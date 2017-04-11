# **Rubocop Suppression**
# rubocop:disable LineLength

require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, AzureNetwork)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

cloud_name = node.workorder.cloud.ciName
ag_service = nil
if !node.workorder.services['lb'].nil? && !node.workorder.services['lb'][cloud_name].nil?
  ag_service = node.workorder.services['lb'][cloud_name]
end

if ag_service.nil?
  OOLog.fatal('missing application gateway service')
end

platform_name = node.workorder.box.ciName
environment_name = node.workorder.payLoad.Environment[0]['ciName']
assembly_name = node.workorder.payLoad.Assembly[0]['ciName']
org_name = node.workorder.payLoad.Organization[0]['ciName']
security_group = "#{environment_name}.#{assembly_name}.#{org_name}"
resource_group_name = node['platform-resource-group']
subscription_id = ag_service[:ciAttributes]['subscription']
location = ag_service[:ciAttributes][:location]

asmb_name = assembly_name.gsub(/-/, '').downcase
plat_name = platform_name.gsub(/-/, '').downcase
env_name = environment_name.gsub(/-/, '').downcase
ag_name = "ag-#{plat_name}"

tenant_id = ag_service[:ciAttributes][:tenant_id]
client_id = ag_service[:ciAttributes][:client_id]
client_secret = ag_service[:ciAttributes][:client_secret]

OOLog.info("Cloud Name: #{cloud_name}")
OOLog.info("Org: #{org_name}")
OOLog.info("Assembly: #{asmb_name}")
OOLog.info("Platform: #{platform_name}")
OOLog.info("Environment: #{env_name}")
OOLog.info("Location: #{location}")
OOLog.info("Security Group: #{security_group}")
OOLog.info("Resource Group: #{resource_group_name}")
OOLog.info("Application Gateway: #{ag_name}")

begin
  credentials = Utils.get_credentials(tenant_id, client_id, client_secret)
  application_gateway = AzureNetwork::Gateway.new(resource_group_name, ag_name, credentials, subscription_id)

  public_ip_name = Utils.get_component_name('lb_publicip', node.workorder.rfcCi.ciId)

  application_gateway.delete
  public_ip_obj = AzureNetwork::PublicIp.new(credentials, subscription_id)
  public_ip_obj.delete(resource_group_name, public_ip_name)
rescue => e
  OOLog.fatal("Error deleting Application Gateway: #{e.message}")
end
