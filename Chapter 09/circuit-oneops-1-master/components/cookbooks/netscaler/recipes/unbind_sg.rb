#
# Cookbook Name:: netscaler
# Recipe:: unbind_sg
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
   # binding from service to lbvserver
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lbvserver_name}").body)
  
  Chef::Log.info("lbvserver_servicegroup_binding "+resp_obj.inspect)
    
  if resp_obj["lbvserver_servicegroup_binding"].nil?
    Chef::Log.info("No service group bindings exist for lbvserver #{lbvserver_name}")
  else  
    lb[:sg].each do |sg_name|
      binding = { :name => lbvserver_name, :servicegroupname => sg_name }
      req = 'object={"params":{"action": "unbind"}, "lbvserver_servicegroup_binding" : ' + JSON.dump(binding) + '}'
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=> :post,
        :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lbvserver_name}",
        :body => req).body)
  
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "delete bind #{sg_name} to #{lbvserver_name} resp: #{resp_obj.inspect}")
        exit 1
      else
        Chef::Log.info( "delete bind #{sg_name} to #{lbvserver_name} resp: #{resp_obj.inspect}")
      end
    end
   end   
end
