#
# Cookbook Name:: netscaler
# Recipe:: delete_services
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

n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)

lb = node.workorder.payLoad.DependsOn[0]
lb_name = lb[:ciName]+'-'+lb[:ciId].to_s

rfc = node.workorder.rfcCi.ciAttributes
iport =  rfc[:iport]
vport =  rfc[:vport]
protocol = node["ns_iport_service_type"]

cloud_name = node.workorder.cloud.ciName
env_name = node.workorder.payLoad["Environment"][0]["ciName"]
platform_name = node.workorder.box.ciName

computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/}
computes.each do |compute|
  
  ip = compute["ciAttributes"]["private_ip"]
  next if ip.nil?

  # service
  # sdc-d1-pricing-app1_8080tcp
  # cloud-env-platform-ci_id-porttcp
  
  service_name = [ cloud_name, env_name, platform_name, compute["ciId"].to_s, 
                   protocol.upcase+'_'+iport+"tcp"].join("-")
  
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/lbvserver_service_binding/#{lb_name}").body)        
          
  binding = Array.new
  if !resp_obj["lbvserver_service_binding"].nil?          
     binding = resp_obj["lbvserver_service_binding"].select{|v| v["servicename"] == service_name }
  end
  if binding.size != 0

    req = 'object= { "lbvserver_service_binding" : {'
    req += "\"servicename\":\"#{service_name}\","
    req += "\"weight\":\"100\","
    req += "\"name\":\"#{lb_name}\"}}"
      
    resp_obj = JSON.parse(node.ns_conn.request( 
      :method=>:put, 
      :path=>"/nitro/v1/config/lbvserver_service_binding/#{lb_name}?action=unbind", 
      :body => URI::encode(req)).body)
    
    puts "post unbind #{service_name} resp: #{resp_obj.inspect}"
  else 
    puts "bind already removed #{resp_obj.inspect}"
  end   
  

  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/service/#{service_name}").body)        
  
  if resp_obj["message"] !~ /No Service/
      
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/service/#{service_name}").body)
    
    puts "service #{service_name} delete #{service_name} resp: #{resp_obj.inspect}"
  else 
    puts "service #{service_name} already removed: #{resp_obj.inspect}"
  end
  
end

# include_recipe "netscaler::delete_monitor"
