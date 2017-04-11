require 'azure_mgmt_compute'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

## NOTE: This recipe is tobe deleted. It is replaced by
## Utils.get_credentials() in azure/libraries/azure_utils.rb

cloud_name = node['workorder']['cloud']['ciName']
cloud_service =
  node['workorder']['services']['compute'][cloud_name]['ciAttributes']
tenant_id = cloud_service['tenant_id']
client_id = cloud_service['client_id']
client_secret = cloud_service['client_secret']
subscription = cloud_service['subscription']

Chef::Log.info("tenant_id: #{tenant_id} client_id: #{client_id} client_secret: #{client_secret} subscription: #{subscription}")
begin
  # Create authentication objects
  token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
  if token_provider != nil
    credentials = MsRest::TokenCredentials.new(token_provider)
    node.set['azureCredentials'] = credentials
  else
    raise e
  end
rescue MsRestAzure::AzureOperationError => e
  OOLog.fatal("Error acquiring a token from Azure: #{e.body}")
rescue => ex
  OOLog.fatal("Error acquiring a token from Azure: #{ex.message}")
end
