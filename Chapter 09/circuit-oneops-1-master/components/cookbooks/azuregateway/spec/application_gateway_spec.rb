# **Rubocop Suppression**
# rubocop:disable LineLength
require 'simplecov'
require 'rest-client'
SimpleCov.start
require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require 'azure_mgmt_network'

include Azure::ARM::Network
include Azure::ARM::Network::Models

describe AzureNetwork::Gateway do
  before do
    token_provider = MsRestAzure::ApplicationTokenProvider.new('tenant_id', 'client_id', 'client_secret')
    credentials = MsRest::TokenCredentials.new(token_provider)
    subscription_id = '<SUBSCRIPTION_ID>'
    resource_group_name = '<RG_NAME>'
    ag_name = '<AG_NAME>'

    @gateway = AzureNetwork::Gateway.new(resource_group_name, ag_name, credentials, subscription_id)
  end

  describe '#get_private_ip_address' do
    it 'verifies private ip address of Gateway.' do
      file_path = File.expand_path('get_application_gateway_response.json', __dir__)
      file = File.open(file_path)
      dns_response = file.read
      allow(RestClient).to receive(:get) { dns_response }

      expect(@gateway.get_private_ip_address('<TOKEN>')).to eq('10.0.1.5')
    end
    it 'raises RestClient exception while getting private IP of Gateway' do
      allow(RestClient).to receive(:get)
        .and_raise(RestClient::Exception.new(nil))

      expect { @gateway.get_private_ip_address('<TOKEN>') }.to raise_error('no backtrace')
    end
    it 'raises RestClient exception with error code 404 while getting api response' do
      allow(RestClient).to receive(:get)
        .and_raise(RestClient::Exception.new(nil, 404))

      expect { @gateway.get_private_ip_address('<TOKEN>') }.to_not raise_error('no backtrace')
    end
    it 'raises exception while parsing invalid json response' do
      allow(RestClient).to receive(:get) {}
      expect { @gateway.get_private_ip_address('<TOKEN>') }.to raise_error('no backtrace')
    end
  end

  describe '#set_gateway_configuration' do
    it 'checks gateway configuration object name' do
      subnet = double
      @gateway.set_gateway_configuration(subnet)

      expect(@gateway.gateway_attributes[:gateway_configuration]).to_not eq(nil)
    end
  end

  describe '#set_backend_address_pool' do
    it 'checks backend pool object name' do
      backend_address_list = ['10.0.2.5/24']
      @gateway.set_backend_address_pool(backend_address_list)

      expect(@gateway.gateway_attributes[:backend_address_pool]).to_not eq(nil)
    end
  end

  describe '#set_https_settings' do
    it 'varify if cookies are enabled in https settings' do
      @gateway.set_https_settings
      http_settings = @gateway.gateway_attributes[:https_settings]

      expect(http_settings).to_not eq(nil)
      expect(http_settings.name).to eq('gateway_settings')
      expect(http_settings.properties.cookie_based_affinity).to eq(ApplicationGatewayCookieBasedAffinity::Enabled)
    end
    it 'varify if cookies are disabled in https settings' do
      @gateway.set_https_settings(false)
      http_settings = @gateway.gateway_attributes[:https_settings]

      expect(http_settings).to_not eq(nil)
      expect(http_settings.properties.cookie_based_affinity).to eq(ApplicationGatewayCookieBasedAffinity::Disabled)
    end
  end

  describe '#set_gateway_port' do
    it 'verify application gateway front port is 443 if ssl certificate exists' do
      @gateway.set_gateway_port(true)
      gateway_fronend_port = @gateway.gateway_attributes[:gateway_port]

      expect(gateway_fronend_port).to_not eq(nil)
      expect(gateway_fronend_port.name).to eq('gateway_front_port')
      expect(gateway_fronend_port.properties.port).to eq(443)
    end
    it 'verify if application gateway front port is 80 if ssl certificate does not exist' do
      @gateway.set_gateway_port(false)
      gateway_fronend_port = @gateway.gateway_attributes[:gateway_port]

      expect(gateway_fronend_port).to_not eq(nil)
      expect(gateway_fronend_port.properties.port).to eq(80)
    end
  end

  describe '#set_frontend_ip_config' do
    it 'sets the subnet for frontend ip configurations if public IP is nil' do
      public_ip = nil
      subnet = double
      @gateway.set_frontend_ip_config(public_ip, subnet)
      frontend_ip_config = @gateway.gateway_attributes[:frontend_ip_config]

      expect(frontend_ip_config).to_not eq(nil)
      expect(frontend_ip_config.name).to eq('frontend_ip_config')
      expect(frontend_ip_config.properties.private_ipallocation_method).to eq(IpAllocationMethod::Dynamic)
      expect(frontend_ip_config.properties.subnet).to_not eq(nil)
    end
    it 'sets the public IP for frontend ip configurations if public IP is not nil' do
      public_ip = double
      subnet = nil
      @gateway.set_frontend_ip_config(public_ip, subnet)
      frontend_ip_config = @gateway.gateway_attributes[:frontend_ip_config]

      expect(frontend_ip_config).to_not eq(nil)
      expect(frontend_ip_config.properties.public_ipaddress).to_not eq(nil)
    end
  end

  describe '#set_ssl_certificate' do
    it 'checks attribute values of ssl certificate object' do
      data = 'DATA'
      password = 'PASSWORD'
      @gateway.set_ssl_certificate(data, password)
      ssl_certificate = @gateway.gateway_attributes[:ssl_certificate]

      expect(ssl_certificate).to_not eq(nil)
      expect(ssl_certificate.name).to eq('ssl_certificate')
      expect(ssl_certificate.properties.data).to eq(data)
      expect(ssl_certificate.properties.password).to eq(password)
    end
  end

  describe '#set_listener' do
    it 'returns application gateway listener properties with HTTPS protocol' do
      @gateway.set_listener(true)
      listener = @gateway.gateway_attributes[:listener]

      expect(listener).to_not eq(nil)
      expect(listener.name).to eq('gateway_listener')
      expect(listener.properties.protocol).to eq(ApplicationGatewayProtocol::Https)
    end
    it 'returns application gateway listener properties with HTTP protocol' do
      @gateway.set_listener(false)
      listener = @gateway.gateway_attributes[:listener]

      expect(listener).to_not eq(nil)
      expect(listener.name).to eq('gateway_listener')
      expect(listener.properties.protocol).to eq(ApplicationGatewayProtocol::Http)
    end
  end

  describe '#set_gateway_request_routing_rule' do
    it 'checks gateway request routing rule name' do
      @gateway.set_gateway_request_routing_rule
      routing_rule = @gateway.gateway_attributes[:gateway_request_routing_rule]

      expect(routing_rule).to_not eq(nil)
      expect(routing_rule.name).to eq('gateway_request_route_rule')
    end
  end

  describe '#set_gateway_sku' do
    it 'returns gateway sku object having sku name small' do
      sku_name = 'small'
      @gateway.set_gateway_sku(sku_name)
      gateway_sku = @gateway.gateway_attributes[:gateway_sku]

      expect(gateway_sku).to_not eq(nil)
      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardSmall)
    end
    it 'returns gateway sku object having sku name medium' do
      sku_name = 'medium'
      @gateway.set_gateway_sku(sku_name)
      gateway_sku = @gateway.gateway_attributes[:gateway_sku]

      expect(gateway_sku).to_not eq(nil)
      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardMedium)
    end
    it 'returns gateway sku object having sku name large' do
      sku_name = 'large'
      @gateway.set_gateway_sku(sku_name)
      gateway_sku = @gateway.gateway_attributes[:gateway_sku]

      expect(gateway_sku).to_not eq(nil)
      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardLarge)
    end
    it 'returns gateway sku object having sku name medium' do
      sku_name = 'ANY_OTHER'
      @gateway.set_gateway_sku(sku_name)
      gateway_sku = @gateway.gateway_attributes[:gateway_sku]

      expect(gateway_sku).to_not eq(nil)
      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardMedium)
    end
  end

  describe '#get_gateway' do
    it 'checks gateway_object attribute values' do
      location = 'EAST-US'
      ssl_certificate_exist = true

      gateway_object = @gateway.get_gateway(location, ssl_certificate_exist)
      expect(gateway_object.name).to eq('<AG_NAME>')
      expect(gateway_object.location).to eq(location)
    end
  end

  describe '#create_or_update' do
    it 'creates application gateway successfully' do
      gateway = double
      promise = double
      response = double
      allow(response).to receive(:body) { 'BODY' }
      allow(promise).to receive(:value!) { response }
      allow(@gateway.client.application_gateways).to receive(:create_or_update) { promise }
      create_gw = @gateway.create_or_update(gateway)

      expect(create_gw).to_not eq(nil)
    end
    it 'raises AzureOperationError exception while creating application gateway' do
      gateway = double
      allow(@gateway.client.application_gateways).to receive(:create_or_update)
        .and_raise(MsRestAzure::AzureOperationError.new('Errors'))

      expect { @gateway.create_or_update(gateway) }.to raise_error('no backtrace')
    end
    it 'raises exception while creating application gateway' do
      gateway = double

      allow(@gateway.client.application_gateways).to receive(:create_or_update)
        .and_raise(MsRest::HttpOperationError.new('Error'))

      expect { @gateway.create_or_update(gateway) }.to raise_error('no backtrace')
    end
  end

  describe '#delete' do
    it 'deletes application gateway successfully' do
      promise = double
      response = double
      allow(response).to receive(:body) { 'BODY' }
      allow(promise).to receive(:value!) { response }
      allow(@gateway.client.application_gateways).to receive(:delete) { promise }
      delete_gw = @gateway.delete

      expect(delete_gw).to_not eq(nil)
    end
    it 'raises AzureOperationError exception' do
      allow(@gateway.client.application_gateways).to receive(:delete)
        .and_raise(MsRestAzure::AzureOperationError.new('Errors'))

      expect { @gateway.delete }.to raise_error('no backtrace')
    end
    it 'raises exception while deleting application gateway' do
      allow(@gateway.client.application_gateways).to receive(:delete)
        .and_raise(MsRest::HttpOperationError.new('Error'))

      expect { @gateway.delete }.to raise_error('no backtrace')
    end
  end
end
