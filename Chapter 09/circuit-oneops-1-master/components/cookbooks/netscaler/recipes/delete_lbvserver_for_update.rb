#
# Cookbook Name:: netscaler
# Recipe:: delete_lbvserver_for_update
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

# cleanup_loadbalancers set in lb::get_lb_name
#

node.cleanup_loadbalancers.each do |lb|
  
  lbvserver_name = lb[:name]

  resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/lbvserver/#{lbvserver_name}").body)        
  if resp_obj["message"] !~ /No such resource/
      
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/lbvserver/#{lbvserver_name}").body)
    
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "delete #{lbvserver_name} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "delete #{lbvserver_name} resp: #{resp_obj.inspect}")
    end
    
  else 
    Chef::Log.info( "lb already removed: #{resp_obj.inspect}")
  end

end