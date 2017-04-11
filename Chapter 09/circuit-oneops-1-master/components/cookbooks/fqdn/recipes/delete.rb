# Cookbook Name:: fqdn
# Recipe:: delete
#
# Copyright 2012, OneOps
#
# All rights reserved - Do Not Redistribute
#
# builds a list of entries based on entrypoint, aliases, and  then sets then in the set_dns_entries recipe
# no ManagedVia - recipes will run on the gw


extend Fqdn::Base
Chef::Resource::RubyBlock.send(:include, Fqdn::Base)


env = node.workorder.payLoad["Environment"][0]["ciAttributes"]
depends_on = { "ciClassName" => "" }
depends_on = node.workorder.payLoad["DependsOn"][0] if node.workorder.payLoad.has_key?("DependsOn")
cloud_name = node[:workorder][:cloud][:ciName]
provider = get_provider

# skip deletes if other active clouds for same dc
if node[:workorder][:services].has_key?("gdns")
  cloud_service =  node[:workorder][:services][:gdns][cloud_name]
end

node.set["is_last_active_cloud_in_dc"] = true
if node.workorder.box.ciAttributes.has_key?("is_platform_enabled") &&
   node.workorder.box.ciAttributes.is_platform_enabled == 'true' &&
   node.workorder.payLoad.has_key?("activeclouds") && !cloud_service.nil?
   node.workorder.payLoad["activeclouds"].each do |service|

     if service[:ciAttributes].has_key?("gslb_site_dns_id") &&
        service[:nsPath] != cloud_service[:nsPath] &&
        service[:ciAttributes][:gslb_site_dns_id] == cloud_service[:ciAttributes][:gslb_site_dns_id]

        Chef::Log.info("not last active cloud in DC. #{service[:nsPath].split("/").last}")
        node.set["is_last_active_cloud_in_dc"] = false
     end
   end
end

node.set["is_last_active_cloud"] = true
if node.workorder.box.ciAttributes.has_key?("is_platform_enabled") &&
   node.workorder.box.ciAttributes.is_platform_enabled == 'true' &&
   node.workorder.payLoad.has_key?("activeclouds") && !cloud_service.nil?
   node.workorder.payLoad["activeclouds"].each do |service|

     if service[:nsPath] != cloud_service[:nsPath]
        Chef::Log.info("not last active cloud: #{service[:nsPath].split("/").last}")
        node.set["is_last_active_cloud"] = false
     end
   end
end

include_recipe "fqdn::get_authoritative_nameserver"

if env.has_key?("global_dns") && env["global_dns"] == "true" &&
   depends_on["ciClassName"] =~ /Lb/ &&
   node.is_last_active_cloud_in_dc

  if provider =~ /azuredns/
    include_recipe "azuretrafficmanager::delete"
  else
    include_recipe "netscaler::get_gslb_domain"
    include_recipe "netscaler::delete_gslb_service"
    include_recipe "netscaler::delete_gslb_vserver"
    include_recipe "netscaler::logout"
  end
end

node.set[:dns_action] = "delete"
include_recipe 'fqdn::build_entries_list'

if provider =~ /azuredns/
  include_recipe 'azuredns::set_dns_records'
else
	include_recipe "fqdn::get_#{provider}_connection"
  include_recipe 'fqdn::set_dns_entries_'+provider
end
