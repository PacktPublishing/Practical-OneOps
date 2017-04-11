require 'azure_mgmt_resources'
require 'json'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Resources)
::Chef::Recipe.send(:include, Azure::ARM::Resources::Models)

# Set the proxy if apiproxy exists as a system var.
env_vars = node['workorder']['ci']['ciAttributes']['env_vars']
env_vars_hash = JSON.parse(env_vars)
Chef::Log.info("APIPROXY is: #{env_vars_hash['apiproxy']}")
if !env_vars_hash['apiproxy'].nil?
  ENV['http_proxy'] = env_vars_hash['apiproxy']
  ENV['https_proxy'] = env_vars_hash['apiproxy']
end

subscription_details = node[:workorder][:ci][:ciAttributes]

subscription_id = subscription_details[:subscription]
resource_group_name = subscription_details[:resource_group]
tenant_id = subscription_details['tenant_id']
client_id = subscription_details['client_id']
client_secret = subscription_details['client_secret']
express_route_enabled = subscription_details['express_route_enabled']
OOLog.info("tenant_id: #{tenant_id} client_id: #{client_id} client_secret: #{client_secret} subscription: #{subscription_id}")

# Create authentication objects

token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, client_secret)
if !token_provider.nil?
  credentials = MsRest::TokenCredentials.new(token_provider)
end

if express_route_enabled == 'true'
  begin
    client = ResourceManagementClient.new(credentials)
    client.subscription_id = subscription_id
    # First, check if resource group is already created
    response = client.resource_groups.check_existence(resource_group_name).value!
    OOLog.info('response from azure:' + response.inspect)
    if response.body == true
      OOLog.info('Subscription details entered are verified')
    else
      OOLog.fatal("Error verifying the subscription and credentials for #{subscription_id}")
    end
  rescue MsRestAzure::AzureOperationError => e
    Chef::Log.error("Error verifying the subscription and credentials for #{subscription_id}")
    node.set['status_result'] = 'Error'
    if e.body != nil
      error_response = e.body['error']
      Chef::Log.error('Error Response code:' + error_response['code'] + '\n\rError Response message:' + error_response['message'])
      OOLog.fatal(error_response['message'])
    else
      Chef::Log.error('Error:' + e.inspect)
      OOLog.fatal('Error verifying the subscription and credentials for #{subscription_id}')
    end
  end
elsif express_route_enabled == 'false' || express_route_enabled == nil
  begin
  client = ResourceManagementClient.new(credentials)
  client.subscription_id = subscription_id
  # First, get list if resources associated with subdcription just to verify subscription and credentials
  promise = client.resource_groups.list()
  response = promise.value!
  OOLog.debug('response from azure:' + response.inspect)
  if response.body != nil
    OOLog.info('Subscription details entered are verified')
  else
    raise e
  end
rescue MsRestAzure::AzureOperationError => e
  Chef::Log.error("Error verifying the subscription and credentials for #{subscription_id}")
  node.set['status_result'] = 'Error'
  if e.body != nil
    error_response = e.body['error']
    Chef::Log.error('Error Response code:' + error_response['code'] + '\n\rError Response message:' + error_response['message'])
    OOLog.fatal(error_response['message'])
  else
    Chef::Log.error('Error:' + e.inspect)
    OOLog.fatal("Error verifying the subscription and credentials for #{subscription_id}")
  end
end
end
