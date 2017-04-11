#
# Cookbook Name:: netscaler
# Recipe:: delete_server
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


computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
computes.each do |compute|

  ip = compute["ciAttributes"]["private_ip"]
  server_key = ip
  next if ip.nil?

  if compute["ciAttributes"].has_key?("instance_name") &&
    !compute["ciAttributes"]["instance_name"].empty?
    
    server_key = compute["ciAttributes"]["instance_name"]
  end
  
  
  puts "server_key: #{server_key}"
  
  # check for server
  resp_obj = JSON.parse(node.ns_conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/server/#{server_key}").body)
  
  puts "resp OBJ: #{resp_obj.inspect}"
  
  # delete if there
  if resp_obj["message"] !~ /No such resource/  
  
    resp_obj = JSON.parse(node.ns_conn.request(
      :method => :delete, 
      :path => "/nitro/v1/config/server/#{server_key}").body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 1335
      Chef::Log.error( "delete #{server_key} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "delete #{server_key} resp: #{resp_obj.inspect}")
    end
    
  else 
    Chef::Log.info( "delete exists: #{resp_obj.inspect}")
  end
  
  
  # backward compliance for when server name was ip
  server_key = ip
  puts "old server_key: #{server_key}"
  
  # check for server
  resp_obj = JSON.parse(node.ns_conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/server/#{server_key}").body)
  
  puts "resp OBJ: #{resp_obj.inspect}"
  
  # delete if there
  if resp_obj["message"] !~ /No such resource/  
  
    resp_obj = JSON.parse(node.ns_conn.request(
      :method => :delete, 
      :path => "/nitro/v1/config/server/#{server_key}").body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 1335
      Chef::Log.error( "delete #{server_key} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "delete #{server_key} resp: #{resp_obj.inspect}")
    end
    
  else 
    Chef::Log.info( "delete exists: #{resp_obj.inspect}")
  end  

end
