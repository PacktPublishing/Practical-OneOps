require File.expand_path('../../libraries/network_security_group.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/utils.rb', __FILE__)
require File.expand_path('../../../azure/libraries/resource_group.rb', __FILE__)

::Chef::Recipe.send(:include, AzureNetwork)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

include_recipe 'azure::get_credentials'
credentials = node['azureCredentials']

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

subscription = compute_service[:subscription]
network_security_group_name = node[:name]

# Get resource group name
resource_group_name =
  AzureResources::ResourceGroup.get_name(org,
                                         assembly,
                                         platform_ci_id,
                                         environment,
                                         location)

 # Creating security rules objects
nsg = AzureNetwork::NetworkSecurityGroup.new(credentials, subscription)
nsg_result = nsg_result = nsg.delete_security_group(resource_group_name, network_security_group_name)

if nsg_result.nil?
  Chef::Log.info("The network security group #{network_security_group_name} has been deleted")
else
  raise 'Error deleting network security group'
end