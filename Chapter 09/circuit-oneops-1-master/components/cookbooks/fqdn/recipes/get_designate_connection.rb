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

#
# Cookbook Name:: fqdn
# Recipe:: get_designate_connection
#

require 'excon'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
service = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
domain_name = service[:zone] 
domain_name += "."

user = {"username" => service[:username],
        "password" => service[:password]}

auth_req = {"auth" => {"tenantName" => service[:tenant],
                       "passwordCredentials" => user}}

host = service[:endpoint].gsub("/v2.0/tokens","")                      
Chef::Log.info("endpoint: #{host}")                                              
conn = Excon.new(host, :ssl_verify_peer => false)
resp = conn.request(:method=>:post, :path=> '/v2.0/tokens', :body => JSON.dump(auth_req))
auth_token = JSON.parse(resp.body)['access']['token']['id']
  
conn = Excon.new(service[:endpoint].gsub(":5000/v2.0/tokens",":9001"),
  :ssl_verify_peer => false,
  :headers => {
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json',
    'X-Auth-Token' => auth_token
   })
  
# Set the connection object
node.set["designate_conn"] = conn
  
  
zone = nil
domains = JSON.parse(conn.request(:method => :get, :path => '/v1/domains').body)['domains']
found_zone = false
domains.each do |domain_entry| 
  if domain_entry['name'] == domain_name
    Chef::Log.info("domain: #{domain_entry.inspect}")
    zone = domain_entry
    found_zone = true
    break
  end  
end

if !found_zone
  create_domain_req = { :name => domain_name, :email => service[:domain_owner_email] }    
  zone = JSON.parse(conn.request(:method => :post, 
               :path => '/v1/domains', 
               :body => JSON.dump(create_domain_req)).body)
end
    
if zone.nil?
  Chef::Log.error("could not get or create zone: #{domain_name}")
  exit 1
end
node.set["designate_zone"] = zone
