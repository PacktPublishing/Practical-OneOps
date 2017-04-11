# Cookbook Name:: fqdn
# Recipe:: add
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

# builds a list of entries based on entrypoint, aliases, and then sets them in the set_dns_entries recipe
# no ManagedVia - recipes will run on the gw

extend Fqdn::Base
Chef::Resource::RubyBlock.send(:include, Fqdn::Base)

# cleanup old platform version entries
if node.workorder.box.ciAttributes.is_active == "false"
  Chef::Log.info("platform is_active false - only performing deletes")
  include_recipe "fqdn::delete"
  return
end

# get the cloud and provider
cloud_name = node[:workorder][:cloud][:ciName]
Chef::Log.debug("Cloud name is: #{cloud_name}")
provider = get_provider

# check for gdns service
gdns_service = nil
if node[:workorder][:services].has_key?("gdns") &&
   node[:workorder][:services][:gdns].has_key?(cloud_name)

   Chef::Log.debug('Setting GDNS Service')
   gdns_service = node[:workorder][:services][:gdns][cloud_name]
end

# getting the environment attributes
env = node.workorder.payLoad["Environment"][0]["ciAttributes"]
Chef::Log.debug("Env is: #{env}")

# skip in active (A/B update)
box = node[:workorder][:box][:ciAttributes]
if box.has_key?(:is_active) && box[:is_active] == "false"
  Chef::Log.info("skipping due to platform is_active false")
  return
end

include_recipe "fqdn::get_authoritative_nameserver"

# netscaler gslb
depends_on_lb = false
node.workorder.payLoad["DependsOn"].each do |dep|
  depends_on_lb = true if dep["ciClassName"] =~ /Lb/
end

Chef::Log.info("Depends on LB is: #{depends_on_lb}")
if env.has_key?("global_dns") && env["global_dns"] == "true" && depends_on_lb &&
   !gdns_service.nil? && gdns_service["ciAttributes"]["gslb_authoritative_servers"] != '[]'
   if provider !~ /azuredns/
      include_recipe "netscaler::get_dc_lbvserver"
      include_recipe "netscaler::add_gslb_vserver"
      include_recipe "netscaler::add_gslb_service"
      include_recipe "netscaler::logout"
  end
end

node.set['dns_action'] = 'create'
#build the entry list
include_recipe 'fqdn::build_entries_list'


# remove the old aliases
if provider =~ /azuredns/
  include_recipe 'azuredns::remove_old_aliases'
else
  include_recipe "fqdn::get_#{provider}_connection"
  include_recipe 'fqdn::remove_old_aliases_'+provider
end

# set the records
if provider =~ /azuredns/
  include_recipe 'azuredns::set_dns_records'
  include_recipe 'azuredns::update_dns_on_pip'

  if env.has_key?("global_dns") && env["global_dns"] == "true" && depends_on_lb
    include_recipe "azuretrafficmanager::add"
  end
else
  include_recipe 'fqdn::set_dns_entries_'+provider
end
