#
# Cookbook Name:: netscaler
# Recipe:: add_service
#
# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# *************
# obsolete code - now lbvserver are bound to servicegroups. this is not called from lb cookbook
# only here for example to use service api


n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)

include_recipe "netscaler::add_monitor"


cloud_name = node.workorder.cloud.ciName
platform_name = node.workorder.box.ciName
env_name = node.workorder.payLoad.Environment[0]["ciName"]

rfc = node.workorder.rfcCi.ciAttributes
iport =  rfc[:iport]
vport =  rfc[:vport]
protocol = node["ns_iport_service_type"]

ip_map = {}

computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/}
# remove old service bindings before adds
computes.each do |compute|  
  ip = compute["ciAttributes"]["private_ip"]
  next if ip.nil?
  ip_map[ip]=1
end


node.loadbalancers.each do |lb|

lb_name = lb[:name]

  resp_obj = JSON.parse(node.ns_conn.request(
       :method=>:get, 
       :path=>"/nitro/v1/config/lbvserver_service_binding/#{lb_name}").body)
  
  if resp_obj["errorcode"] != 0
    Chef::Log.error( "get bindings for  #{lb_name} failed... resp: #{resp_obj.inspect}")
    exit 1 
  end
  
  services = resp_obj["lbvserver_service_binding"]
  services = [] if services.nil?
  services.each do |service|
    if !ip_map.has_key?(service["ipv46"]) || 
      ( service["port"] != iport && ip_map.has_key?(service["ipv46"]))
      
      Chef::Log.error("deleting: "+service.inspect)
        
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=>:delete, 
        :path=>"/nitro/v1/config/service/#{service["servicename"]}").body)
  
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "delete #{service[:servicename]} resp: #{resp_obj.inspect}")
        exit 1      
      else
        Chef::Log.info( "delete #{service[:servicename]} resp: #{resp_obj.inspect}")
      end
      
    end
    
  end
  
end

# add services
computes.each do |compute|
  
  ip = compute["ciAttributes"]["private_ip"]
  server_key = ip
  next if ip.nil?
  
  if compute["ciAttributes"].has_key?("instance_name") &&
    !compute["ciAttributes"]["instance_name"].empty?
    
    server_key = compute["ciAttributes"]["instance_name"]
  end
  
  # service
  # sdc-d1-pricing-app1_8080tcp
  # cloud-env-platform-ci_id-porttcp
  service_name = [ cloud_name, env_name, platform_name, compute["ciId"].to_s, 
                   protocol.upcase+'_'+iport+"tcp"].join("-")

  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/service/#{service_name}").body)        
    
  if resp_obj["message"] =~ /No Service/
 
    service = { 
      :name => service_name,
      :servername => server_key, 
      :port => iport,
      :servicetype => protocol,
      :usip => 'NO'
    }

    # ns nitro v1 api needs this object=
    req = 'object= { "service" : '+JSON.dump(service)+'}'
      
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/service", 
      :body => URI::encode(req)).body)
    
    if resp_obj["errorcode"] != 0
      Chef::Log.info("service: #{service.inspect}")
      Chef::Log.error( "add #{service_name} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "add #{service_name} resp: #{resp_obj.inspect}")          
    end
    
  else 
    Chef::Log.info( "service exists: #{resp_obj.inspect}")
  end


  node.loadbalancers.each do |lb|

    lb_name = lb[:name]
    # binding from service to lbvserver
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:get, 
      :path=>"/nitro/v1/config/lbvserver_service_binding/#{lb_name}").body)        
  
    binding = Array.new
    if !resp_obj["lbvserver_service_binding"].nil?          
       binding = resp_obj["lbvserver_service_binding"].select{|v| v["servicename"] == service_name }
    end
    
    if binding.size == 0
  
      binding = { :name => lb_name, :servicename => service_name, :weight => 1 }    
  
      req = 'object= { "lbvserver_service_binding" : '+JSON.dump(binding)+ '}'
        
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=>:post, 
        :path=>"/nitro/v1/config/lbvserver_service_binding/#{lb_name}?action=bind", 
        :body => URI::encode(req)).body)
  
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "post bind #{service_name} resp: #{resp_obj.inspect}")
        exit 1      
      else
        Chef::Log.info( "post bind #{service_name} resp: #{resp_obj.inspect}")
      end
      
    else 
      Chef::Log.info( "bind exists: #{binding.inspect}")
    end        
    
    
    binding = { :monitorname => node.monitor_name, :servicename => service_name }
    req = 'object= { "lbmonitor_service_binding" : '+JSON.dump(binding)+ '}'
    
    #binding from service to monitor
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:get, 
      :body => URI::encode(req),
      :path=>"/nitro/v1/config/lbmonitor_service_binding/#{node.monitor_name}").body)        
  
    binding = Array.new
    if !resp_obj["lbmonitor_service_binding"].nil?          
       binding = resp_obj["lbmonitor_service_binding"].select{|v| v["servicename"] == service_name }
    end
    
    if binding.size == 0
  
      binding = { :monitorname => node.monitor_name, :servicename => service_name, :weight => 1 }    
  
      req = 'object= { "lbmonitor_service_binding" : '+JSON.dump(binding)+ '}'
        
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=>:post, 
        :path=>"/nitro/v1/config/lbmonitor_service_binding/", 
        :body => URI::encode(req)).body)
  
      if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 2133
        Chef::Log.error( "monitor post bind #{node.monitor_name} to #{service_name} resp: #{resp_obj.inspect}")
        exit 1      
      else
        Chef::Log.info( "monitor post bind #{node.monitor_name} to #{service_name} resp: #{resp_obj.inspect}")
      end
      
    else 
      Chef::Log.info( "monitor bind exists for #{node.monitor_name} to #{service_name}")
    end    

    
  end
  
end

