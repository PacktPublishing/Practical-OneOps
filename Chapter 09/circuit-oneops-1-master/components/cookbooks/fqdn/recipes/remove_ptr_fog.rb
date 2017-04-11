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

# Cookbook Name:: fqdn
# Recipe:: remove_ptr_fog
#
          
ip = node.workorder.rfcCi.ciAttributes.public_ip

ptr = `dig +short -x #{ip}`.split("\n")

if ptr.size > 0  
  include_recipe "fqdn::get_fog_connection"
  Chef::Log.info("ptr: #{ptr.inspect}")    
  name = ptr.first.gsub(/\.$/,"")
 
  record = {:ipv4addr => ip, :ptrdname => name }
  Chef::Log.info("record "+record.inspect)
  
  records = JSON.parse(node.infoblox_conn.request(
    :method=>:get, 
    :path=>"/wapi/v1.0/record:ptr", 
    :body => JSON.dump(record) ).body)
  
  if records.size == 0
    Chef::Log.info("ptr record already deleted")        
  else      
    records.each do |r|      
      ref = r["_ref"]
      resp = node.infoblox_conn.request(:method => :delete, :path => "/wapi/v1.0/#{ref}")
      Chef::Log.info("rm ptr status: #{resp.status}")
      Chef::Log.info("rm ptr response: #{resp.inspect}")
    end      
  end     
  
 
end    
