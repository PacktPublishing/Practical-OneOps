# **Rubocop Suppression**
# rubocop:disable LineLength

require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require File.expand_path('../../../azure/libraries/virtual_network.rb', __FILE__)

require 'azure_mgmt_network'
require 'rest-client'
require 'chef'
require 'json'
require 'base64'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, AzureNetwork)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

include_recipe 'azuredns::get_azure_token'
token = node['azure_rest_token']

def get_compute_nodes
  compute_nodes = []
  compute_list = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
  if compute_list
    # Build compute nodes to load balance
    compute_list.each do |compute|
      compute_nodes.push(compute[:ciAttributes][:private_ip])
    end
  end
  compute_nodes
end

def get_public_ip(location, timeout = 5)
  pip_address_props = PublicIpAddressPropertiesFormat.new
  pip_address_props.idle_timeout_in_minutes = timeout
  pip_address_props.public_ipallocation_method = IpAllocationMethod::Dynamic
  public_ip = PublicIpAddress.new
  public_ip.location = location
  public_ip.properties = pip_address_props
  public_ip
end

def add_gateway_subnet_to_vnet(virtual_network, gateway_subnet_address, gateway_subnet_name)
  if virtual_network.properties.subnets.count > 1

    virtual_network.properties.subnets.each do |subnet|
      if subnet.name == gateway_subnet_name
        OOLog.info('No need to add Gateway subnet. Gateway subnet already exist...')
        return virtual_network
      end
    end
  end

  subnet_properties = Azure::ARM::Network::Models::SubnetPropertiesFormat.new
  subnet_properties.address_prefix = gateway_subnet_address

  subnet = Azure::ARM::Network::Models::Subnet.new
  subnet.name = gateway_subnet_name
  subnet.properties = subnet_properties

  virtual_network.properties.subnets.push(subnet)
  virtual_network
end

def create_public_ip(credentials, subscription_id, location, resource_group_name)
  public_ip_name = Utils.get_component_name('ag_publicip', node['workorder']['rfcCi']['ciId'])
  public_ip_address = get_public_ip(location)
  public_ip_obj = AzureNetwork::PublicIp.new(credentials, subscription_id)
  public_ip_obj.create_update(resource_group_name, public_ip_name, public_ip_address)
end

def get_vnet(resource_group_name, vnet_name, vnet_obj)
  vnet_obj.name = vnet_name
  vnet = vnet_obj.get(resource_group_name)

  if vnet.nil?
    OOLog.fatal("Could not retrieve vnet '#{vnet_name}' from express route")
  end
  vnet.body
end

cloud_name = node.workorder.cloud.ciName
ag_service = nil
if !node.workorder.services['lb'].nil? && !node.workorder.services['lb'][cloud_name].nil?
  ag_service = node.workorder.services['lb'][cloud_name]
end

if ag_service.nil?
  OOLog.fatal('missing application gateway service')
end

compute_service = nil
if !node.workorder.services['compute'].nil? && !node.workorder.services['compute'][cloud_name].nil?
  compute_service = node.workorder.services['compute'][cloud_name]
end

if compute_service.nil?
  OOLog.fatal('missing compute service')
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

network_address = compute_service[:ciAttributes][:network_address].strip

OOLog.info("Cloud Name: #{cloud_name}")
OOLog.info("Org: #{org_name}")
OOLog.info("Assembly: #{asmb_name}")
OOLog.info("Platform: #{platform_name}")
OOLog.info("Environment: #{env_name}")
OOLog.info("Location: #{location}")
OOLog.info("Security Group: #{security_group}")
OOLog.info("Resource Group: #{resource_group_name}")
OOLog.info("Application Gateway: #{ag_name}")

# ===== Create a Application Gateway =====
#   # AG Creation Steps
#
#   # 1 - Create public IP
#   # 2 - Create Gateway Ip Configurations
#   # 3 - Create backend address pool
#   # 4 - Create http settings
#   # 5 - Create FrontendIPConfig
#   # 6 - Create SSL Certificate
#   # 7 - Listener
#   # 8 - Routing rule, SKU
#   # 9 - Create Application Gateway

begin
  credentials = Utils.get_credentials(tenant_id, client_id, client_secret)
  application_gateway = AzureNetwork::Gateway.new(resource_group_name, ag_name, credentials, subscription_id)

  # Determine if express route is enabled
  express_route_enabled = true
  if ag_service[:ciAttributes][:express_route_enabled].nil? || ag_service[:ciAttributes][:express_route_enabled] == 'false'
    express_route_enabled = false
  end

  vnet_obj = AzureNetwork::VirtualNetwork.new(credentials, subscription_id)

  if express_route_enabled
    vnet_name = ag_service[:ciAttributes][:network]
    master_rg = ag_service[:ciAttributes][:resource_group]
    vnet = get_vnet(master_rg, vnet_name, vnet_obj)

    if vnet.properties.subnets.count < 1
      OOLog.fatal("VNET '#{vnet_name}' does not have subnets")
    end
  else
    # Create public IP
    public_ip = create_public_ip(credentials, subscription_id, location, resource_group_name)
    vnet_name = 'vnet_' + network_address.gsub('.','_').gsub('/', '_')
    vnet = get_vnet(resource_group_name, vnet_name, vnet_obj)
  end

  gateway_subnet_address = ag_service[:ciAttributes][:gateway_subnet_address]
  gateway_subnet_name = 'GatewaySubnet'

  # Add a subnet for Gateway
  vnet = add_gateway_subnet_to_vnet(vnet, gateway_subnet_address, gateway_subnet_name)
  rg_name = master_rg.nil? ? resource_group_name : master_rg
  vnet = vnet_obj.create_update(rg_name, vnet)
  vnet = vnet.body
  gateway_subnet = nil
  vnet.properties.subnets.each do |subnet|
    if subnet.name == gateway_subnet_name
      gateway_subnet = subnet
      break
    end
  end

  # Application Gateway configuration
  application_gateway.set_gateway_configuration(gateway_subnet)

  # Backend Address Pool
  backend_ip_address_list = get_compute_nodes
  application_gateway.set_backend_address_pool(backend_ip_address_list)

  # Gateway Settings
  data = ''
  password = ''
  ssl_certificate_exist = false
  certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/ }
  certs.each do |cert|
    if !cert[:ciAttributes][:pfx_enable].nil? && cert[:ciAttributes][:pfx_enable] == 'true'
      data = cert[:ciAttributes][:ssl_data]
      password = cert[:ciAttributes][:ssl_password]
      ssl_certificate_exist = true
    end
  end

  enable_cookie = true
  if ag_service[:ciAttributes][:cookies_enabled].nil? || ag_service[:ciAttributes][:cookies_enabled] == 'false'
    enable_cookie = false
  end

  # Gateway SSL Certificate
  if ssl_certificate_exist
    if data == '' || password == ''
      OOLog.fatal("PFX Data or Password is nil or empty. Data = #{data} - Password = #{password}")
    end
    application_gateway.set_ssl_certificate(data, password)
  end

  # Cookies must be enabled in case of SSL offload.
  enable_cookie = ssl_certificate_exist == true ? true : enable_cookie
  application_gateway.set_https_settings(enable_cookie)

  # Gateway Front Port
  application_gateway.set_gateway_port(ssl_certificate_exist)

  # Gateway Frontend IP Configuration
  application_gateway.set_frontend_ip_config(public_ip, gateway_subnet)

  # Gateway Listener
  application_gateway.set_listener(ssl_certificate_exist)

  # Gateway Request Route Rule
  application_gateway.set_gateway_request_routing_rule

  # Gateway SKU
  sku_name = ag_service[:ciAttributes][:gateway_size]
  application_gateway.set_gateway_sku(sku_name)

  # Create Gateway Object
  gateway = application_gateway.get_gateway(location, ssl_certificate_exist)

  gateway_result = application_gateway.create_or_update(gateway)

  if gateway_result.nil?
    # Application Gateway was not created.
    OOLog.fatal("Application Gateway '#{ag_name}' could not be created")
  else
    ag_ip = nil
    if express_route_enabled
      ag_ip = application_gateway.get_private_ip_address(token)
    else
      ag_ip = public_ip.properties.ip_address
    end

    if ag_ip.nil? || ag_ip == ''
      OOLog.fatal("Application Gateway '#{gateway_result.name}' NOT configured with IP")
    else
      OOLog.info("AzureAG IP: #{ag_ip}")
      node.set[:azure_ag_ip] = ag_ip
    end
  end
rescue => e
  OOLog.fatal("Error creating Application Gateway: #{e.message}")
end
