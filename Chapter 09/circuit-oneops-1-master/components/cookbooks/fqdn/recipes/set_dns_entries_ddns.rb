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
def get_record_type (dns_name, dns_values)
  record_type = "cname"
  ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
  if ips.size > 0
    record_type = "a"
  end
  if dns_name =~ /^\d+\.\d+\.\d+\.\d+$/
    record_type = "ptr"
  end

  return record_type
end


def delete_dns (dns_name, dns_value)

  delete_type = get_record_type(dns_name,[dns_value])
  Chef::Log.info("delete #{delete_type}: #{dns_name} to #{dns_value}")
  
  ddns_execute "update delete #{dns_name} #{delete_type.upcase} #{dns_value}"
    
end



include_recipe "fqdn::get_ddns_connection"

cloud_name = node[:workorder][:cloud][:ciName]
domain_name = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:zone]
cmd_file = node.ddns_key_file + '-cmd'
ns = node.ns

deletable_values = []
if node.has_key?("deletable_entries")
  node.deletable_entries.each do |deletable_entry|
    if deletable_entry[:values].is_a?(String)
      deletable_values.push(deletable_entry[:values])
    else
      deletable_values += deletable_entry[:values]
    end
  end
end

deletable_values.uniq!

#
# delete / create dns entries
#
node[:entries].each do |entry|
  dns_match = false
  dns_name = entry[:name]
  dns_values = entry[:values].is_a?(String) ? Array.new([entry[:values]]) : entry[:values]

  dns_type = get_record_type(dns_name,dns_values)

  if dns_name.empty? || dns_name =~ /^\*$/
   Chef::Log.error("invalid dns_name: #{dns_name}")
   exit 1
  end

  # put a value for wildcard dns entries
  dns_name_for_lookup = dns_name.gsub("\*","abc123")
  Chef::Log.info("#{dns_name_for_lookup} new values: "+dns_values.sort.inspect)

  existing_dns = get_existing_dns(dns_name,ns)

  Chef::Log.info("previous entries: #{node.previous_entries}")
  Chef::Log.info("deletable_values: #{deletable_values}")
  
  
  if existing_dns.length > 0 || node[:dns_action] == "delete"
    
    # cleanup or delete
    existing_dns.each do |existing_entry|
      if deletable_values.include?(existing_entry) &&
         (dns_values.include?(existing_entry) && node[:dns_action] == "delete") ||          
         # value was in previous entry, but not anymore
         (!dns_values.include?(existing_entry) &&
          node.previous_entries.has_key?(dns_name) &&
          node.previous_entries[dns_name].include?(existing_entry) && 
          node[:dns_action] != "delete")

        delete_dns(dns_name, existing_entry)
      end
    end

  end

  # delete workorder skips the create call
  if node[:dns_action] == "delete"
    next
  end


  # infoblox has multiple record values for round-robin entries
  # View attribute extracted from infoblox metadata to make it configurable item
  dns_values.each do |dns_value|
    
    if existing_dns.include?(dns_value)
      Chef::Log.info("exists #{dns_type}: #{dns_name} to #{dns_values.to_s}")
      next        
    end
    
    Chef::Log.info("create #{dns_type}: #{dns_name} to #{dns_values.to_s}")
    
    ttl = 60
    if node.workorder.rfcCi.ciAttributes.has_key?("ttl")
      ttl = node.workorder.rfcCi.ciAttributes.ttl.to_i
    end
    
    type = get_record_type(dns_name,[dns_value]).upcase
    ddns_execute "update add #{dns_name} #{ttl} #{type} #{dns_value}"
    
  end
  if !verify(dns_name,dns_values,ns)
    fail_with_fault "could not verify: #{dns_name} to #{dns_values} on #{ns} after 5min."
  end

end

File.delete(node.ddns_key_file)
if File.exists?(cmd_file)
  File.delete(cmd_file)  
end
