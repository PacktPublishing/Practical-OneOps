require File.expand_path('../../libraries/traffic_managers.rb', __FILE__)
require File.expand_path('../../libraries/model/traffic_manager.rb', __FILE__)
require File.expand_path('../../libraries/model/dns_config.rb', __FILE__)
require File.expand_path('../../libraries/model/monitor_config.rb', __FILE__)
require File.expand_path('../../libraries/model/endpoint.rb', __FILE__)
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

def get_public_ip(network_client, resource_group_name, public_ip_name)
  Chef::Log.info('Searching for public ip ' + public_ip_name + ' within resource group ' + resource_group_name)
  begin
    promise = network_client.public_ip_addresses.get(resource_group_name, public_ip_name)
    public_ip = promise.value!
    Chef::Log.info('Found public ip ' + public_ip_name)
  rescue MsRestAzure::AzureOperationError => e
    Chef::Log.error('Error getting public ip ' + public_ip_name)
    Chef::Log.error('Error: ' + e.body.to_s)
    exit 1
  end
  return public_ip.body
end

def get_load_balancer(network_client, resource_group_name, load_balancer_name)
  Chef::Log.info('Searching for load balancer ' + load_balancer_name + ' within resource group ' + resource_group_name)
  begin
    promise = network_client.load_balancers.get(resource_group_name, load_balancer_name)
    load_balancer = promise.value!
    Chef::Log.info('Found load balancer ' + load_balancer_name)
  rescue MsRestAzure::AzureOperationError => e
    Chef::Log.warn('Load balancer not found')
    Chef::Log.warn('Error: ' + e.body.to_s)
    return nil
  end
  return load_balancer.body
end

def get_public_ip_fqdns(network_client, resource_group_names, nsPathParts)
  assembly = nsPathParts[2]
  environment_name = nsPathParts[3]
  platform_name = nsPathParts[5]
  plat_name = platform_name.gsub(/-/, "").downcase
  load_balancer_name = "lb-#{plat_name}"
  public_ip_fqdns = Array.new

  resource_group_names.each do |resource_group_name|
    load_balancer = get_load_balancer(network_client, resource_group_name, load_balancer_name)
    if !load_balancer.nil?
      public_ip_id = load_balancer.properties.frontend_ipconfigurations[0].properties.public_ipaddress.id
      public_ip_id_array = public_ip_id.split('/')
      public_ip_name = public_ip_id_array[8]
      public_ip = get_public_ip(network_client, resource_group_name, public_ip_name)
      public_ip_fqdn = public_ip.properties.dns_settings.fqdn
      Chef::Log.info('Obtained public ip fqdn ' + public_ip_fqdn + ' to be used as endpoint for traffic manager')
      public_ip_fqdns.push(public_ip_fqdn)
    end
  end
  return public_ip_fqdns
end

def get_token(dns_attributes)
  tenant_id = dns_attributes['tenant_id']
  client_id = dns_attributes['client_id']
  client_secret = dns_attributes['client_secret']
  begin
    token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
    if token_provider != nil
      token = MsRest::TokenCredentials.new(token_provider)
      return token
    else
      raise "Could not retrieve azure credentials"
      exit 1
    end
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error acquiring authentication token from azure")
    raise e
  end
end

def initialize_monitor_config
  listeners = node.workorder.payLoad.lb[0][:ciAttributes][:listeners]
  protocol = listeners.tr('[]"', '').split(' ')[0].upcase

  monitor_port = listeners.tr('[]"', '').split(' ')[1]
  monitor_path = '/'
  monitor_config = MonitorConfig.new(protocol, monitor_port, monitor_path)
  return monitor_config
end

def display_traffic_manager_fqdn(dns_name)
  fqdn = dns_name + '.' + 'trafficmanager.net'
  ip = ''
  entries = node.set[:entries]
  entries.push({:name => fqdn, :values => ip })
  entries_hash = {}
  entries.each do |entry|
    key = entry[:name]
    entries_hash[key] = entry[:values]
  end
  puts "***RESULT:entries=#{JSON.dump(entries_hash)}"
end

def initialize_dns_config(dns_attributes, gdns_attributes)
  domain = dns_attributes['zone']
  domain_without_root = domain.split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
  subdomain = node['workorder']['payLoad']['Environment'][0]['ciAttributes']['subdomain']
  if !subdomain.empty?
    dns_name = subdomain + '.' + domain_without_root
  else
    dns_name = domain_without_root
  end
  relative_dns_name = dns_name.tr('.', '-').slice!(0, 60)
  Chef::Log.info('The Traffic Manager FQDN is ' + relative_dns_name)
  display_traffic_manager_fqdn(relative_dns_name)

  dns_ttl = gdns_attributes['ttl']
  dns_config = DnsConfig.new(relative_dns_name, dns_ttl)
  return dns_config
end

def initialize_endpoints(targets)
  endpoints = Array.new
  for i in 0..targets.length-1
    location = targets[i].split('.').reverse[3]
    endpoint_name = 'endpoint_' + location + '_' + i.to_s
    endpoint = EndPoint.new(endpoint_name, targets[i], location)
    endpoint.set_endpoint_status(EndPoint::Status::ENABLED)
    endpoint.set_weight(1)
    endpoint.set_priority(i+1)
    endpoints.push(endpoint)
  end
  return endpoints
end

def initialize_traffic_manager(public_ip_fqdns, dns_attributes, gdns_attributes)
  endpoints = initialize_endpoints(public_ip_fqdns)
  dns_config = initialize_dns_config(dns_attributes, gdns_attributes)
  monitor_config = initialize_monitor_config
  traffic_routing_method = gdns_attributes['traffic-routing-method']
  traffic_manager = TrafficManager.new(traffic_routing_method, dns_config, monitor_config, endpoints)
  return traffic_manager
end

def get_resource_group_names()
  nsPathParts = node["workorder"]["rfcCi"]["nsPath"].split("/")
  org = nsPathParts[1]
  assembly = nsPathParts[2]
  environment = nsPathParts[3]
  platform = nsPathParts[5]

  resource_group_names = Array.new
  remotegdns_list = node['workorder']['payLoad']['remotegdns']
  remotegdns_list.each do |remotegdns|
    location = remotegdns['ciAttributes']['location']
    resource_group_name = org[0..15] + '-' + assembly[0..15] + '-' + node.workorder.box.ciId.to_s + '-' + environment[0..15] + '-' + Utils.abbreviate_location(location)
    resource_group_names.push(resource_group_name)
  end
  Chef::Log.info("remotegdns resource groups: " + resource_group_names.to_s )
  return resource_group_names
end

def get_traffic_manager_resource_group(resource_group_names, profile_name, subscription, traffic_manager, azure_token)
  resource_group_names.each do |resource_group_name|
    traffic_manager_processor = TrafficManagers.new(resource_group_name, profile_name, subscription, traffic_manager, azure_token)
    Chef::Log.info("Checking traffic manager FQDN set in resource group: " + resource_group_name)
    status_code = traffic_manager_processor.get_profile
    if status_code == 200
      return resource_group_name
    end
  end
  return nil
end
#################################################
#                                               #
#################################################

#set the proxy if it exists as a cloud var
Utils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

nsPathParts = node['workorder']['rfcCi']['nsPath'].split('/')
cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']
subscription = dns_attributes['subscription']
gdns_attributes = node['workorder']['services']['gdns'][cloud_name]['ciAttributes']

token = get_token(dns_attributes)
network_client = NetworkResourceProviderClient.new(token)
network_client.subscription_id = subscription

resource_group_names = get_resource_group_names()
public_ip_fqdns = get_public_ip_fqdns(network_client, resource_group_names, nsPathParts)
traffic_manager = initialize_traffic_manager(public_ip_fqdns, dns_attributes, gdns_attributes)

include_recipe 'azuredns::get_azure_token'
azure_token = node['azure_rest_token']
platform_name = nsPathParts[5]
profile_name = 'trafficmanager-' + platform_name

resource_group_name = get_traffic_manager_resource_group(resource_group_names, profile_name, subscription, traffic_manager, azure_token)
if resource_group_name.nil? then
  include_recipe 'azure::get_platform_rg_and_as'
  resource_group_name = node['platform-resource-group']
  traffic_manager_processor = TrafficManagers.new(resource_group_name, profile_name, subscription, traffic_manager, azure_token)
  status_code = traffic_manager_processor.create_update_profile
  if ![200, 201].include? status_code
    Chef::Log.error("Failed to create traffic manager.")
    exit 1
  end
else
  traffic_manager_processor = TrafficManagers.new(resource_group_name, profile_name, subscription, traffic_manager, azure_token)
  status_code = traffic_manager_processor.delete_profile
  if [200, 204].include? status_code
    status_code = traffic_manager_processor.create_update_profile
    if ![200, 201].include? status_code
      Chef::Log.error("Failed to recreate traffic manager.")
      exit 1
    end
  else
    Chef::Log.error("Failed to delete traffic manager.")
    exit 1
  end
end

Chef::Log.info("Exiting Traffic Manager Add with response status code: " + status_code.to_s)
