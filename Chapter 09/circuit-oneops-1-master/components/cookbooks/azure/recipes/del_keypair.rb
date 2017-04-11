#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

# NOTE: There is no recipe for deleting Availability Set.
# An Availability Set is created as part of a Resource Group.
# Therefore, deleting a Resource Group will delete ALL
# resources within it. Thus, deleting any Availability Sets

require 'azure_mgmt_resources'
require File.expand_path('../../libraries/availability_set.rb', __FILE__)
require File.expand_path('../../libraries/resource_group.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

::Chef::Recipe.send(:include, AzureCompute)
::Chef::Recipe.send(:include, AzureResources)

# get all necessary info from node
cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]
nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
org = nsPathParts[1]
assembly = nsPathParts[2]
environment = nsPathParts[3]
platform_ci_id = node[:workorder][:box][:ciId]
location = compute_service[:location]

resource_group = AzureResources::ResourceGroup.new(compute_service)

# get the resource group name
rg_name =
  AzureResources::ResourceGroup.get_name(org,
                                         assembly,
                                         platform_ci_id,
                                         environment,
                                         location)

#First check to see if the resource group exists.
rg = resource_group.get(rg_name)
if rg
  OOLog.info("Deleting Resource Group '#{rg_name}' ... ")
  resource_group.delete(rg_name)
else
  # it doesn't exist.
  OOLog.info("Resource Group '#{rg_name}' doesn't exists.")
end
