require_relative 'spec_helper'
require_relative 'rspec_constants'
require 'azure_mgmt_network'
require File.expand_path('../../libraries/network_security_group.rb', __FILE__)


RSpec.describe  do

  def nsg
    token_provider = MsRestAzure::ApplicationTokenProvider.new(TENANT_ID, CLIENT_ID, CLIENT_SECRET)
    credentials = MsRest::TokenCredentials.new(token_provider)
    AzureNetwork::NetworkSecurityGroup.new(credentials,SUBSCRIPTION_ID)
  end
  
  def sec_rule
    AzureNetwork::NetworkSecurityGroup.create_rule_properties(SECURITY_RULE_NAME,SECURITY_RULE_ACCESS,SECURITY_RULE_DESCRIPTION,SECURITY_RULE_DESTINATION_ADDRESS_PREFIX,SECURITY_RULE_DESTINATION_PORT_RANGE,SECURITY_RULE_DIRECTION,SECURITY_RULE_PRIORITY,SECURITY_RULE_PROTOCOL,SECURITY_RULE_PROVISIONING_STATE,SECURITY_RULE_SOURCE_ADDRESS_PREFIX,SECURITY_RULE_SOURCE_PORT_RANGE)
  end
  
  describe '#create_rule_properties' do
    context 'fill the parameters' do
      it 'returns a security rule object' do
        expect(sec_rule).not_to be_nil
      end 
    end
  end

  describe '#list_security_groups' do
    context 'when search into a resource group' do
      it 'response must not be nil' do
        expect(nsg.list_security_groups(RESOURCE_GROUP)).not_to be_nil
      end
    end
end

  describe '#create_update' do
    context 'when parameters is not nil' do
      it 'returns the created/updated network security group' do
       
        security_rules = Array.new << sec_rule
        parameters = NetworkSecurityGroup.new
        parameters.location = LOCATION

        nsg_props = NetworkSecurityGroupPropertiesFormat.new
        nsg_props.security_rules = security_rules
        parameters.properties = nsg_props
        
        expect(nsg.create_update(RESOURCE_GROUP,NETWORK_SECURITY_GROUP_NAME,parameters).properties.security_rules[0].name).to eq(SECURITY_RULE_NAME)
          
      end      
    end
  end

end