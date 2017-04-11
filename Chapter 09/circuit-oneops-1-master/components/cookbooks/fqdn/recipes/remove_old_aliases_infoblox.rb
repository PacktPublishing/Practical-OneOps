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
# Recipe:: remove_old_aliases
#
# builds a list of dns entries based on entrypoint, aliases, zone and platform
# no ManagedVia - recipes will run on the gw

require 'excon'
   
# ex) customer_domain: env.asm.org.oneops.com
customer_domain = node.customer_domain
if node.customer_domain !~ /^\./
  customer_domain = '.'+node.customer_domain
end

# entries Array of {name:String, values:Array}
entries = Array.new
aliases = Array.new
current_aliases = Array.new
full_aliases = Array.new
current_full_aliases = Array.new
ns = node.ns

if node.workorder.rfcCi.ciBaseAttributes.has_key?("aliases")
  begin
   aliases = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse aliases json: "+node.workorder.rfcCi.ciBaseAttributes.aliases)
  end
end

if node.workorder.rfcCi.ciAttributes.has_key?("aliases")
  begin
    current_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse aliases json: "+node.workorder.rfcCi.ciAttributes.aliases)
  end
end

current_aliases.each do |active_alias|
  aliases.delete(active_alias)
end


if node.workorder.rfcCi.ciBaseAttributes.has_key?("full_aliases")
  begin
   full_aliases = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse full_aliases json: "+node.workorder.rfcCi.ciBaseAttributes.full_aliases)
  end
end

if node.workorder.rfcCi.ciAttributes.has_key?("full_aliases")
  begin
    current_full_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse full_aliases json: "+node.workorder.rfcCi.ciAttributes.full_aliases)
  end
end

if !current_full_aliases.nil?
  current_full_aliases.each do |active_full_alias|
    full_aliases.delete(active_full_alias)
  end
end

aliases.each do |a|
  alias_name = a + customer_domain  
  values = `dig +short CNAME #{alias_name} @#{ns}`.split("\n").first
  if values.nil?
    values = `dig +short #{alias_name} @#{ns}`.split("\n").first
  end

  Chef::Log.info("alias dns_name: "+alias_name)

  if !values.nil?
    entries.push({:name => alias_name, :values => [ values.gsub(/\.$/,"") ] })
  else
    Chef::Log.info("already removed: "+alias_name)
  end

  if node.workorder.cloud.ciAttributes.priority == "1"
     cloud_name = node.workorder.cloud.ciName
     service = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
     if service[:cloud_dns_id].nil? || service[:cloud_dns_id].empty?
       Chef::Log.info(" no cloud_dns_id - service: #{service.inspect} ")
       next
     end

     # remove cloud_dns_id for primary
     alias_platform_dns_name = alias_name.gsub("\."+service[:cloud_dns_id]+"\."+service[:zone],"."+service[:zone]).downcase

     values = `dig +short CNAME #{alias_platform_dns_name} @#{ns}`.split("\n").first
     if values.nil?
       values = `dig +short #{alias_platform_dns_name} @#{ns}`.split("\n").first
     end

     Chef::Log.info("alias dns_name: "+alias_platform_dns_name)
     if !values.nil?
       entries.push({:name => alias_platform_dns_name, :values => [ values.gsub(/\.$/,"") ] })
     else
       Chef::Log.info("already removed: "+alias_platform_dns_name)
     end

  end
end


full_aliases.each do |full_alias|
  values = `dig +short CNAME #{full_alias} @#{ns}`.split("\n").first
  if values.nil?
    values = `dig +short #{full_alias} @#{ns}`.split("\n").first
  end

  
  Chef::Log.info("full_alias dns_name: "+full_alias)
  if !values.nil?
    values.gsub!(/\.$/,"")
    is_removable = false
    node.deletable_entries.each do |record|
      if record[:name].include?(full_alias) && record[:values].include?(values)
        is_removable = true
      end
    end
    
    if is_removable
      entries.push({:name => full_alias, :values => [ values.gsub(/\.$/,"") ] })
    else
      Chef::Log.info("will not remove existing cname: #{full_alias} -> #{values}")
    end
  else
    Chef::Log.info("already removed: "+full_alias)
  end
end

def get_record_type (dns_values)
  record_type = "cname"
  ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
  if ips.size > 0
    record_type = "a"
  end
  return record_type
end


include_recipe "fqdn::get_infoblox_connection"


#
# delete / create dns entries
#
entries.each do |entry|
  dns_match = false
  dns_type = get_record_type(entry[:values])
  dns_name = entry[:name].downcase
  dns_values = entry[:values]

  existing_dns = `dig +short #{dns_name} @#{ns}`.split("\n").map! { |v| v.gsub(/\.$/,"") }

  existing_ips = existing_dns.grep(/\d+\.\d+\.\d+\.\d+/)
  if dns_type == "cname" && existing_ips.size > 0 && existing_dns.size >1
    existing_ips.each do |ip|
       existing_dns.delete(ip)
    end
  end

  existing_comparison = existing_dns.sort <=> dns_values.sort
  Chef::Log.info("remove existing:"+existing_dns.sort.to_s)

  if existing_dns.length > 0
    delete_type = get_record_type(existing_dns)
    Chef::Log.info("delete #{delete_type}: #{dns_name} to #{existing_dns.to_s}")


    infoblox_key = "ipv4addr"
    if delete_type == "cname"
      infoblox_key = "canonical"
    end

    # check for server
    record = { :name => dns_name, infoblox_key => dns_values.first }
    Chef::Log.info("record: #{record.inspect}")
    records = JSON.parse(node.infoblox_conn.request(
      :method=>:get,
      :path=>"/wapi/v1.0/record:#{delete_type}",
      :body => JSON.dump(record) ).body)

    if records.size == 0
      Chef::Log.info("record already deleted")

    else
      records.each do |r|
        ref = r["_ref"]
        resp = node.infoblox_conn.request(:method => :delete, :path => "/wapi/v1.0/#{ref}")
        Chef::Log.info("status: #{resp.status}")
        Chef::Log.info("response: #{resp.inspect}")
      end
    end


  end

end
