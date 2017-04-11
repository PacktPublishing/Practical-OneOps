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
# Recipe:: set_dns_entries
#
# uses node[:entries] list of dns entries based on entrypoint, aliases, zone, and platform to update dns
# no ManagedVia - recipes will run on the gw

# get dns record type - check for ip addresses
def get_record_type (dns_values)
  record_type = "CNAME"
  ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
  if ips.size > 0
    record_type = "A"
  end     
  return record_type
end

# set in get_designate_connection  
zone = node.designate_zone
conn = node.designate_conn
ns = node.ns

#
# delete / create dns entries
#
node[:entries].each do |entry|
  dns_match = false
  dns_name = entry[:name]
  dns_values = entry[:values].is_a?(String) ? Array.new([entry[:values]]) : entry[:values]
  dns_type = get_record_type(dns_values) 
  
  existing_dns = `dig +short #{dns_name} @#{ns}`.split("\n")
  
  existing_ips = existing_dns.grep(/\d+\.\d+\.\d+\.\d+/)
  if dns_type == "CNAME" && existing_ips.size > 0 && existing_dns.size >1
    existing_ips.each do |ip|
       existing_dns.delete(ip)      
    end
  end
  
  existing_comparison = existing_dns.sort <=> dns_values.sort
  Chef::Log.info("new values:"+dns_values.sort.to_s)  
  Chef::Log.info("existing:"+existing_dns.sort.to_s)
    
  if existing_dns.length > 0 && (existing_comparison != 0 || node[:dns_action] == "delete")
    delete_type = get_record_type(existing_dns)
    Chef::Log.info("delete #{delete_type}: #{dns_name} to #{existing_dns.to_s}") 

    records = JSON.parse(conn.request(:method => :get, 
                 :path => '/v1/domains/'+zone[:id]+'/records').body)["records"]
    
    Chef::Log.info("attempting to delete some of: #{records.inspect}")
    matching_records = records.select { |r| r['name'] == dns_name +'.' && r['data'] == dns_values.first}
    matching_records.each do |record|
      resp = JSON.parse(conn.request(:method => :delete, 
                   :path => '/v1/domains/'+zone[:id]+'/records/'+record['id']).body)
      
      Chef::Log.info("delete resp: #{resp.inspect}")                                          
    end
  else
    if existing_dns.length > 0
      dns_match = true
    end
  end
  
  # delete workorder skips the create call
  if node[:dns_action] == "delete"
    next
  end
  
  if dns_match
    Chef::Log.info("exists #{dns_type}: #{dns_name} to #{dns_values.to_s}") 
  else
    ttl = 60
    if node.workorder.rfcCi.ciAttributes.has_key?("ttl")
      ttl = node.workorder.rfcCi.ciAttributes.ttl.to_i
    end
 
    puts "zone: #{zone.inspect}"
    record = { :name => dns_name +'.', :type => dns_type, :data => dns_values.first, :ttl => ttl }        
    Chef::Log.info("create #{record.inspect}")
    record_result = JSON.parse(conn.request(:method => :post, 
                 :path => '/v1/domains/'+zone[:id]+'/records', 
                 :body => JSON.dump(record)).body)
                 
    Chef::Log.info("record: #{record_result.inspect}")
            
    if !verify(dns_name,dns_values,ns)
      fail_with_fault "could not verify: #{dns_name} to #{dns_values} on #{ns} after 5min."
    end
    
  end
end
