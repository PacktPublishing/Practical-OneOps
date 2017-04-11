#
# Cookbook Name:: keypair
# Recipe:: update
#

include_recipe "shared::set_provider"
  OOLog.debug("node[:provider_class] ==> "+node[:provider_class])
if node[:provider_class] =~ /azure/
  return
else
  include_recipe "keypair::delete"
  include_recipe "keypair::add"
end
