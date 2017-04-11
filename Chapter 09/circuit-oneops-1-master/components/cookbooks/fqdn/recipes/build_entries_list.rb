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
# Recipe:: build_entries_list
#
# builds a list of dns entries based on entrypoint, DependsOn, (full) aliases, cloud and platform
#

extend Fqdn::Base
Chef::Resource::RubyBlock.send(:include, Fqdn::Base)

cloud_name = node[:workorder][:cloud][:ciName]
service_attrs = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
  
# ex) customer_domain: env.asm.org.oneops.com
customer_domain = node.customer_domain.downcase
if node.customer_domain.downcase !~ /^\./
  customer_domain = '.'+node.customer_domain.downcase
end

# entries Array of {name:String, values:Array}
entries = Array.new

# used to prevent full,short aliases on hostname entries
is_hostname_entry = false

if !node.workorder.payLoad.has_key?(:DependsOn)
  fail_with_fault "missing DependsOn payload"
end

lbs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Lb/ }

if node.workorder.payLoad.has_key?("Entrypoint")
 ci = node.workorder.payLoad.Entrypoint[0]
 dns_name = (ci[:ciName] +customer_domain).downcase

elsif lbs.size > 0
 ci = lbs.first
 ci_name_parts = ci[:ciName].split('-')
 # remove instance and cloud id from ci name
 ci_name_parts.pop
 ci_name_parts.pop 
 ci_name = ci_name_parts.join('-')
 dns_name = (ci_name + customer_domain).downcase

else
  os = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Os/ }

  if os.size == 0

    ci_name = node.workorder.payLoad.RealizedAs.first['ciName']
    Chef::Log.info("using the manifest/RealizedAs ciName: #{ci_name}")
    dns_name = (ci_name + "." + node.workorder.box.ciName + customer_domain).downcase
   
  else

    if os.size > 1
      fail_with_fault "unsupported usecase - need to check why there are multiple os for same fqdn"
    end
    is_hostname_entry = true
    ci = os.first

    provider_service = node[:workorder][:services][:dns][cloud_name][:ciClassName].split(".").last.downcase
    if provider_service =~ /azuredns/
      dns_name = (ci[:ciAttributes][:hostname]).downcase
    else
      dns_name = (ci[:ciAttributes][:hostname] + customer_domain).downcase
    end
  end
end


# short aliases which will use the customer/env domain
aliases = Array.new
if node.workorder.rfcCi.ciAttributes.has_key?("aliases") && !is_hostname_entry
  begin
    aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse aliases json: "+node.workorder.rfcCi.ciAttributes.aliases)
  end
end

# full aliases uses as-is, cnamed to the platform entry
full_aliases = Array.new
if node.workorder.rfcCi.ciAttributes.has_key?("full_aliases") && !is_hostname_entry
  begin
    full_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse full_aliases json: "+node.workorder.rfcCi.ciAttributes.full_aliases)
  end
end


if service_attrs[:cloud_dns_id].nil? || service_attrs[:cloud_dns_id].empty?
  fail_with_fault "no cloud_dns_id for dns cloud service: #{cloud_service[:nsPath]} #{cloud_service[:ciName]}"
end

# values using DependsOn's dns_record attr
deps = node.workorder.payLoad[:DependsOn].select { |d| d[:ciAttributes].has_key? "dns_record" }
values = get_dns_values(deps)

# cloud-level add entry - will loop thru and cleanup & create them later
entries.push({:name => dns_name, :values => values })
Chef::Log.info("cloud level dns: #{dns_name} values: "+values.to_s)
deletable_entries = [{:name => dns_name, :values => values }]


# cloud-level short aliases
aliases.each do |a|
  next if a.empty? 
  # skip if user has a short alias same as platform name
  next if a == node.workorder.box.ciName
  alias_name = a + customer_domain
  Chef::Log.info("short alias dns_name: #{alias_name} values: "+dns_name)
  entries.push({:name => alias_name, :values => dns_name })
  deletable_entries.push({:name => alias_name, :values => dns_name })
end


# platform-level remove cloud_dns_id for primary entry
primary_platform_dns_name = dns_name.gsub("\."+service_attrs[:cloud_dns_id]+"\."+service_attrs[:zone],"."+service_attrs[:zone]).downcase


if node.workorder.rfcCi.ciAttributes.has_key?("ptr_enabled") &&
  node.workorder.rfcCi.ciAttributes.ptr_enabled == "true"

  ptr_value = dns_name
  if node.workorder.rfcCi.ciAttributes.ptr_source == "platform"
    ptr_value = primary_platform_dns_name
    if is_hostname_entry
      ptr_value = node.workorder.box.ciName
      ptr_value += customer_domain.gsub("\."+service_attrs[:cloud_dns_id]+"\."+service_attrs[:zone],"."+service_attrs[:zone])
    end
  end

  values.each do |ip|
    next unless ip =~ /^\d+\.\d+\.\d+\.\d+$/ || ip =~ Resolv::IPv6::Regex
    ptr = {:name => ip, :values => ptr_value.downcase}
    Chef::Log.info("ptr: #{ptr.inspect}")
    entries.push(ptr)
    deletable_entries.push(ptr)
  end
end


 # platform level
if node.workorder.cloud.ciAttributes.priority != "1"

  # clear platform if not primary and not gslb
  if !node.has_key?("gslb_domain")
    entries.push({:name => primary_platform_dns_name, :values => [] })
  end
  
else

  if node.has_key?("gslb_domain") && !node.gslb_domain.nil?
    value_array = [ node.gslb_domain ]
  else
    # infoblox doesnt support round-robin cnames so need to get other primary cloud-level ip's
    value_array = []
    if values.class.to_s == "String"
      value_array.push(values)
    else
      value_array += values
    end

  end
  
  is_a_record = false
  value_array.each do |val|
    if val =~ /^\d+\.\d+\.\d+\.\d+$/ || val =~ Resolv::IPv6::Regex
      is_a_record = true
    end
  end

  if node.dns_action != "delete" ||
    (node.dns_action == "delete" && node.is_last_active_cloud) ||
    (node.dns_action == "delete" && is_a_record)

    entries.push({:name => primary_platform_dns_name, :values => value_array })
    deletable_entries.push({:name => primary_platform_dns_name, :values => value_array })
    Chef::Log.info("primary platform dns: #{primary_platform_dns_name} values: "+value_array.inspect)
  else
    Chef::Log.info("not deleting #{primary_platform_dns_name} because its not the last one")
  end


  aliases.each do |a|
    next if a.empty?
    next if node.dns_action == "delete" && !node.is_last_active_cloud
    # skip if user has a short alias same as platform name
    next if a == node.workorder.box.ciName

    alias_name = a  + customer_domain
    alias_platform_dns_name = alias_name.gsub("\."+service_attrs[:cloud_dns_id]+"\."+service_attrs[:zone],"."+service_attrs[:zone]).downcase

    if node.has_key?("gslb_domain") && !node.gslb_domain.nil?
      primary_platform_dns_name = node.gslb_domain
    end

    Chef::Log.info("alias dns_name: #{alias_platform_dns_name} values: "+primary_platform_dns_name)
    entries.push({:name => alias_platform_dns_name, :values => primary_platform_dns_name })
    deletable_entries.push({:name => alias_platform_dns_name, :values => primary_platform_dns_name })
  end

  if !full_aliases.nil?
    full_aliases.each do |full|
      next if node.dns_action == "delete" && !node.is_last_active_cloud

      full_value = primary_platform_dns_name
      if node.has_key?("gslb_domain") && !node.gslb_domain.nil?
        full_value = node.gslb_domain
      end


      Chef::Log.info("full alias dns_name: #{full} values: #{full_value} hijackable: #{node.workorder.rfcCi.ciAttributes.hijackable_full_aliases}")
      entries.push({:name => full, :values => full_value, :is_hijackable => node.workorder.rfcCi.ciAttributes.hijackable_full_aliases })
      deletable_entries.push({:name => full, :values => full_value})
    end
  end

end

if node.has_key?("dc_entry")
  if node.dns_action != "delete" ||
    (node.dns_action == "delete" && node.is_last_active_cloud_in_dc)

    entries.push(node.dc_entry)
    deletable_entries.push(node.dc_entry)
  end
end

entries_hash = {}
entries.each do |entry|
  key = entry[:name]
  entries_hash[key] = entry[:values]
end
puts "***RESULT:entries=#{JSON.dump(entries_hash)}"

# pass to set_dns_entries
node.set[:entries] = entries


previous_entries = {}
if node.workorder.rfcCi.ciBaseAttributes.has_key?("entries")
  previous_entries = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.entries)
end
if node.workorder.rfcCi.ciAttributes.has_key?("entries")
  previous_entries.merge!(JSON.parse(node.workorder.rfcCi.ciAttributes['entries']))
end
node.set[:previous_entries] = previous_entries

previous_entries.each do |k,v|
  deletable_entries.push({:name => k, :values => v})
end
node.set[:deletable_entries] = deletable_entries
