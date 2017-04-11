#
# Cookbook Name:: netscaler
# Recipe:: bind_sg
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


node.loadbalancers.each do |lb|
  
  lbvserver_name = lb[:name]
  
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lbvserver_name}").body)
  
  Chef::Log.info("lbvserver_servicegroup_binding "+resp_obj.inspect)
  
  lb[:sg].each do |sg_name|
    
    if !resp_obj["lbvserver_servicegroup_binding"].nil?
      resp_obj["lbvserver_servicegroup_binding"].each do |binding|
        bound_sg_name = binding["servicegroupname"]
        if(sg_name == bound_sg_name)
          Chef::Log.info("Not binding as service group #{sg_name} already bound to lbvserver #{lbvserver_name}")
          return
        end
      end
    else
      Chef::Log.info("no sg bound to lbvserver #{lbvserver_name}")
    end
    
     Chef::Log.info("binding lbvserver #{lbvserver_name} to service group #{sg_name}")
     
     
     resp_obj = JSON.parse(node.ns_conn.request(
         :method=>:get, 
         :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)
    
     if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 258
      Chef::Log.error( "get servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
      exit 1
     else
      Chef::Log.info("servicegroup exists :: #{resp_obj}")   
     end
     
     
     binding = { :name => lbvserver_name, :servicegroupname => sg_name }
     req = '{ "lbvserver_servicegroup_binding" : '+JSON.dump(binding)+ '}'
     resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:put,
      :path=>"/nitro/v1/config/",
      :body => req).body)
  
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "post bind #{sg_name} to #{lbvserver_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "post bind #{sg_name} to #{lbvserver_name} resp: #{resp_obj.inspect}")
    end
  end  
 
 end
