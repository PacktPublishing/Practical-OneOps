require 'azure_mgmt_network'

#set the proxy if it exists as a cloud var
Utils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
OOLog.info("azuredns:update_dns_on_pip.rb - platform-resource-group is: #{node['platform-resource-group']}")

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']

# Check for lb service
# will need to get out of this if application gateway is enabled.
cloud_service = nil
application_gateway_enabled = false
if !node.workorder.services["lb"].nil? &&
  !node.workorder.services["lb"][cloud_name].nil?

  cloud_service = node.workorder.services["lb"][cloud_name]
  Chef::Log.info("FQDN:: Cloud service name: #{cloud_service[:ciClassName]}")

  # Checks if Application Gateway service is enabled
  if cloud_service[:ciClassName].split(".").last.downcase =~ /azuregateway/
    application_gateway_enabled = true
    Chef::Log.info("FQDN::add Application Gateway Enabled: #{application_gateway_enabled}")
  end
end

express_route_enabled = dns_attributes['express_route_enabled']
Chef::Log.info("express_route_enable is: #{express_route_enabled}")

if express_route_enabled == 'true' && application_gateway_enabled
  # skip this if it's private ips and has application gateway.
  return 0
end

subscription = dns_attributes['subscription']
resource_group = node['platform-resource-group']
tenant_id = dns_attributes['tenant_id']
client_id = dns_attributes['client_id']
client_secret = dns_attributes['client_secret']

credentials = Utils.get_credentials(tenant_id, client_id, client_secret)

zone_name = dns_attributes['zone']
zone_name = zone_name.split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
zone_name = zone_name.tr('.', '-')

public_ip = AzureDns::PublicIp.new(resource_group, credentials, subscription, zone_name)

domain_name_label = public_ip.update_dns(node)
node.set['domain_name_label'] = domain_name_label unless domain_name_label.nil?
