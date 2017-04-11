#
# Cookbook Name:: netscaler
# Recipe:: add_servicegroup
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

def clear_non_generic_monitor(conn,servicegroup_name,monitor_name)
  
  Chef::Log.info("delete monitor to migrate to generic monitor")
  binding_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/servicegroup_lbmonitor_binding/#{servicegroup_name}").body)
    
  if !binding_obj['servicegroup_lbmonitor_binding'].nil? && 
     !binding_obj['servicegroup_lbmonitor_binding'].find{|sg| sg['monitor_name'] == monitor_name}.nil?
       
    binding = { :monitor_name => monitor_name, :servicegroupname => servicegroup_name }
    Chef::Log.info("binding being deleted for migration to generic monitor: #{binding.inspect}")
    req = URI::encode('object={"params":{"action": "unbind"}, "servicegroup_lbmonitor_binding" : ' + JSON.dump(binding) + '}')
    resp_obj = JSON.parse(conn.request(
      :method=> :post,
      :path=>"/nitro/v1/config/servicegroup_lbmonitor_binding/#{servicegroup_name}",
      :body => req).body)

    if ![0,258].include?(resp_obj["errorcode"])
      Chef::Log.error( "delete bind #{binding.inspect} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "delete bind  #{binding.inspect} resp: #{resp_obj.inspect}")
    end
  end

  mon_response  = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)
    
  mon_detail = []
  if mon_response.has_key?('lbmonitor') 
    mon_detail = mon_response['lbmonitor']
  end
      
  if mon_detail.size > 0
    type = mon_detail[0]['type']
      
    res_mon = JSON.parse(conn.request(
      :method=>:delete,
      :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}?args=type:#{type}").body)
    
    if res_mon['errorcode'] != 2131 && res_mon['errorcode'] != 0
      Chef::Log.error( "delete monitor #{monitor_name} resp: #{res_mon.inspect}")
      exit 1
    else
      Chef::Log.info( "delete monitor #{monitor_name} resp: #{res_mon.inspect}")
    end    
  end
       
end

sg_names = []
lbs = [] + node.loadbalancers + node.dcloadbalancers

env_name = node.workorder.payLoad.Environment[0]["ciName"]
platform_name = node.workorder.box.ciName
cloud_name = node.workorder.cloud.ciName

lbCi = node.workorder.rfcCi
rfc = node.workorder.rfcCi.ciAttributes

#cleanup old servicegroups before old monitors
cleanup_servicegroups = []
if rfc.has_key?("inames")
  cleanup_servicegroups = JSON.parse(rfc["inames"])
end

# cleanup old servicegroup convention
sg_name = [env_name, platform_name, cloud_name, lbCi["ciId"].to_s, "svcgrp"].join("-")
cleanup_servicegroups.push sg_name

# remove old servicegroups
lbs.each do |lb|
  # should exist so lets remove from the list used to delete
  cleanup_servicegroups.delete(lb[:sg_name])
end
cleanup_servicegroups.each do |sg|
  Chef::Log.info("cleanup old sg: #{sg}")
  n = netscaler_servicegroup sg do
    connection node.ns_conn
    action :nothing
  end
  n.run_action(:delete)
end


# cleanup different servicetype for other clouds' in same dc
if node.workorder.rfcCi.has_key?("ciBaseAttributes") &&
   node.workorder.rfcCi.ciBaseAttributes.has_key?("listeners")

  old_svc_port = {}
  JSON.parse(node.workorder.rfcCi.ciBaseAttributes.listeners).each do |listener|
    servicetype = listener.split(" ")[2].upcase
    servicetype = "SSL" if servicetype == "HTTPS"
    vservicetype = listener.split(" ")[0].upcase
    vservicetype = "SSL" if vservicetype == "HTTPS"
    vsvc_vport = vservicetype+"_"+listener.split(" ")[1]
    old_svc_port["#{vsvc_vport}"] = servicetype
  end
  
  # filter out new types 
  JSON.parse(node.workorder.rfcCi.ciAttributes.listeners).each do |listener|
    servicetype = listener.split(" ")[2].upcase
    servicetype = "SSL" if servicetype == "HTTPS"
    vservicetype = listener.split(" ")[0].upcase
    vservicetype = "SSL" if vservicetype == "HTTPS"
    vsvc_vport = vservicetype+"_"+listener.split(" ")[1]
    old_svc_port.delete("#{vsvc_vport}") if old_svc_port["#{vsvc_vport}"] == servicetype
  end
  
  Chef::Log.info("old services port: #{old_svc_port.inspect}")
  # servicegroup servicetype changed
  if !old_svc_port.empty?
   
    node.dcloadbalancers.each do |lb|
      lb_name = lb[:name]
      resp_obj = JSON.parse(node.ns_conn.request(:method=>:get,
       :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lb_name}").body)
      
      next if resp_obj["lbvserver_servicegroup_binding"].nil?
      
      resp_obj["lbvserver_servicegroup_binding"].each do |binding|
        old_sg_name = binding["servicegroupname"]
        
        # make sure sg servicetype is an old one
        resp_obj = JSON.parse(node.ns_conn.request(:method=>:get,
         :path=>"/nitro/v1/config/servicegroup/#{old_sg_name}").body)
         
        next if resp_obj["servicegroup"].nil?
        
        sg = resp_obj["servicegroup"][0]
        
        old_svc_port.each do |vsvc_vport, stype|
          if lb_name.include?(vsvc_vport)
            next if !stype.include?(sg["servicetype"])
          end
        end
    
        binding = { :name => lb_name, :servicegroupname => old_sg_name }
        req = 'object={"params":{"action": "unbind"}, "lbvserver_servicegroup_binding" : ' + JSON.dump(binding) + '}'
        resp_obj = JSON.parse(node.ns_conn.request(
          :method=> :post,
          :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lb_name}",
          :body => req).body)
    
        if resp_obj["errorcode"] != 0
          Chef::Log.error( "rm old servicetype sg binding #{old_sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
          exit 1
        else
          Chef::Log.info( "rm old servicetype sg binding #{old_sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
        end
      end      
      
                 
    end
  end
end

# process current ones
lbs.each do |lb|
  sg_name = lb[:sg_name]
  unless sg_names.include? sg_name
    sg_names.push sg_name
  end

  # cleanup previous sg
  if node.has_key?("ns_conn_prev")
    
    Chef::Log.info("removing servicegroup from previous az / netscaler.")
    
    n = netscaler_servicegroup sg_name do
      connection node.ns_conn_prev
      action :nothing
    end  
    n.run_action(:delete)
    
  end
  
  n = netscaler_servicegroup sg_name do
    port lb[:iport]
    protocol lb[:iprotocol]
    connection node.ns_conn
    action :nothing
  end

  n.run_action(:create)

  # delete members no longer in the sg
  ip_map = {}
  node.lb_members.each do |compute|
    ip = compute["ciAttributes"]["private_ip"]
    next if ip.nil?
    ip_map[ip]=1
  end

  resp_obj = JSON.parse(node.ns_conn.request(
       :method=>:get,
       :path=>"/nitro/v1/config/servicegroup_servicegroupmember_binding/#{sg_name}").body)

  if resp_obj["errorcode"] != 0
    Chef::Log.error( "get bindings for sg #{sg_name} failed... resp: #{resp_obj.inspect}")
    exit 1
  end

  members = resp_obj["servicegroup_servicegroupmember_binding"]
  members = [] if members.nil?

  members.each do |member|
    member_ip = member["ip"]
    if !ip_map.has_key?(member_ip) ||
      ( member["port"] != lb[:iport].to_i && ip_map.has_key?(member_ip))

      Chef::Log.error("deleting: "+member.inspect)

       binding = {
             "servicegroupname" => sg_name,
             "servername" => member["servername"],
             "port" => member["port"]
           }

      req = 'object={"params":{"action": "unbind"}, "servicegroup_servicegroupmember_binding" : ' + JSON.dump(binding) + '}'
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=> :post,
          :body => req,
          :path=>"/nitro/v1/config/servicegroup_servicegroupmember_binding/#{sg_name}").body)

        if resp_obj["errorcode"] != 0
          Chef::Log.error( "delete #{binding.inspect} resp: #{resp_obj.inspect}")
          exit 1
        else
          Chef::Log.info( "delete #{binding.inspect} resp: #{resp_obj.inspect}")
        end

      end

  end


  # add members
  node.lb_members.each do |compute|

    ip = compute["ciAttributes"]["private_ip"]
    server_name = ip
    next if ip.nil?

    if compute["ciAttributes"].has_key?("instance_name") &&
      !compute["ciAttributes"]["instance_name"].empty?

      server_name = compute["ciAttributes"]["instance_name"]
    end

    port = lb[:iport]
    if lb[:iport] == 'all'
      port = '*'
    end
    
    req = {"servicegroup_servicegroupmember_binding" => {
             "servicegroupname" => sg_name,
             "servername" => server_name,
             "port" => port
             }
           }

    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:put,
      :body => JSON.dump(req),
      :path=>"/nitro/v1/config/").body)

    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 273
       Chef::Log.error("could not bind service to servicegroup resp_obj: #{resp_obj.inspect}")
       exit 1
    end

  end
  
  include_recipe "netscaler::add_monitor"  

  # bind monitors
  node.monitors.each do |mon|    
    next if mon[:iport] != lb[:iport]
    
    # migrate 
    if mon.has_key?('orig_monitor_name')
      clear_non_generic_monitor(node.ns_conn, sg_name, mon[:orig_monitor_name])
    end
      
    binding = { :monitorname => mon[:monitor_name], :servicegroupname => sg_name}
    req = '{ "lbmonitor_servicegroup_binding" : '+JSON.dump(binding)+ '}'  
  
    # always bind servicegroup to monitor    
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:get,
      :path=>"/nitro/v1/config/lbmonbindings_servicegroup_binding/#{mon[:monitor_name]}").body)
  
    Chef::Log.info("lbmonbindings_servicegroup_binding "+resp_obj.inspect)
  
    binding = Array.new
    if !resp_obj["lbmonbindings_servicegroup_binding"].nil?
       binding = resp_obj["lbmonbindings_servicegroup_binding"].select{|v| v["servicegroupname"] == sg_name }
    end
  
    if binding.size == 0
  
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=> :put,
        :path=>"/nitro/v1/config/",
        :body => req).body)
  
      if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 2133
        Chef::Log.error( "monitor put bind #{mon[:monitor_name]} to #{sg_name} resp: #{resp_obj.inspect}")
        exit 1
      else
        Chef::Log.info( "monitor post bind #{mon[:monitor_name]} to #{sg_name} resp: #{resp_obj.inspect}")
      end
  
    else
      Chef::Log.info( "monitor bind exists for #{mon[:monitor_name]} to #{sg_name}")
    end
  end

  lb_name = lb[:name]

  Chef::Log.info("lbvserver-servicegroup binding: #{lb_name} to #{sg_name}")

  # binding from service to lbvserver
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lb_name}").body)
  
  Chef::Log.info("lbvserver_servicegroup_binding "+resp_obj.inspect)
    
  binding = Array.new
  if !resp_obj["lbvserver_servicegroup_binding"].nil?
     binding = resp_obj["lbvserver_servicegroup_binding"].select{|v| v["servicegroupname"] == sg_name }
     Chef::Log.info("lbvserver_servicegroup_binding filtered: "+binding.inspect)
  end

  if binding.size == 0 && !lb.has_key?("is_secondary")

    binding = { :name => lb_name, :servicegroupname => sg_name }
    req = '{ "lbvserver_servicegroup_binding" : '+JSON.dump(binding)+ '}'
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:put,
      :path=>"/nitro/v1/config/",
      :body => req).body)

    if resp_obj["errorcode"] != 0
      Chef::Log.error( "post bind #{sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "post bind #{sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
    end

  elsif binding.size >0 && lb.has_key?("is_secondary")

    binding = { :name => lb_name, :servicegroupname => sg_name }
    req = 'object={"params":{"action": "unbind"}, "lbvserver_servicegroup_binding" : ' + JSON.dump(binding) + '}'
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=> :post,
      :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lb_name}",
      :body => req).body)

    if resp_obj["errorcode"] != 0
      Chef::Log.error( "delete bind #{sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "delete bind #{sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
    end

  elsif binding.size == 0 && lb.has_key?("is_secondary")
    Chef::Log.info( "bind doesn't exist and shouldn't because the cloud is not primary")
  else
    Chef::Log.info( "bind exists: #{binding.inspect}")
  end

end

puts "***RESULT:inames=[\"#{sg_names.join("\",\"")}\"]"
