require 'rest_client'
require 'json'
require ::File.expand_path('../../libraries/token.rb', __FILE__)

cloud_name = node['workorder']['cloud']['ciName']
cloud = node['workorder']['services']['dns'][cloud_name]
dns_attributes = cloud['ciAttributes']

tenant_id = dns_attributes['tenant_id']
client_id = dns_attributes['client_id']
client_secret = dns_attributes['client_secret']

azure_token = AzureDns::Token.new(tenant_id, client_id, client_secret)
node.set['azure_rest_token'] = azure_token.generate_token
