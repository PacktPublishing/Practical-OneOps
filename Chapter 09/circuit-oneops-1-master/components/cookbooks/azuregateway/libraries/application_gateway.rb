# **Rubocop Suppression**
# rubocop:disable LineLength
require 'azure_mgmt_network'
require 'chef'
require 'yaml'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

module AzureNetwork
  # Cookbook Name:: Azuregateway
  class Gateway
    include Azure::ARM::Network
    include Azure::ARM::Network::Models

    attr_accessor :client
    attr_accessor :gateway_attributes
    def initialize(resource_group_name, ag_name, credentials, subscription_id)
      @subscription_id = subscription_id
      @resource_group_name = resource_group_name
      @ag_name = ag_name
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = @subscription_id
      @gateway_attributes = Hash.new
      @configurations = YAML.load_file(File.expand_path('../config/config.yml', __dir__))
    end

    def get_attribute_id(gateway_attribute, attribute_name)
      @configurations['gateway']['subscription_id']  %{subscription_id: @subscription_id, resource_group_name: @resource_group_name, ag_name:@ag_name, gateway_attribute: gateway_attribute, attribute_name: attribute_name}
    end

    def get_private_ip_address(token)
      resource_url = "https://management.azure.com/subscriptions/#{@subscription_id}/resourceGroups/#{@resource_group_name}/providers/Microsoft.Network/applicationGateways/#{@ag_name}?api-version=2016-03-30"
      dns_response = RestClient.get(
          resource_url,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: token
      )
      OOLog.info("Azuregateway::Application Gateway - API response is #{dns_response}")
      dns_hash = JSON.parse(dns_response)
      OOLog.info("Azuregateway::Application Gateway - #{dns_hash}")
      dns_hash['properties']['frontendIPConfigurations'][0]['properties']['privateIPAddress']

    rescue RestClient::Exception => e
      if e.http_code == 404
        OOLog.info('Azuregateway::Application Gateway doesn not exist')
      else
        OOLog.info("***FAULT:Body=#{e.http_body}")
        OOLog.fatal("***FAULT:Message=#{e.message}")
      end
    rescue => e
      OOLog.debug("Azuregateway::Add - Exception is: #{e.message}")
      OOLog.fatal("Exception trying to parse response: #{dns_response}")
    end

    def set_gateway_configuration(subnet)
      gateway_ipconfig = Azure::ARM::Network::Models::ApplicationGatewayIpConfiguration.new
      gateway_ipconfig.name = @configurations['gateway']['gateway_config_name']
      properties = Azure::ARM::Network::Models::ApplicationGatewayIpConfigurationPropertiesFormat.new
      properties.subnet = subnet
      gateway_ipconfig.properties = properties

      @gateway_attributes[:gateway_configuration] = gateway_ipconfig
    end

    def set_backend_address_pool(backend_address_list)
      gateway_backend_pool = ApplicationGatewayBackendAddressPool.new
      backpool_prop = ApplicationGatewayBackendAddressPoolPropertiesFormat.new
      backend_addresses = []
      backend_address_list.each do |backend_address|
        backend_address_obj = ApplicationGatewayBackendAddress.new
        backend_address_obj.ip_address = backend_address
        backend_addresses.push(backend_address_obj)
      end

      backpool_prop.backend_addresses = backend_addresses

      gateway_backend_pool.name = @configurations['gateway']['backend_address_pool_name']
      gateway_backend_pool.id = get_attribute_id('backendAddressPools', gateway_backend_pool.name)
      gateway_backend_pool.properties = backpool_prop

      @gateway_attributes[:backend_address_pool] = gateway_backend_pool
    end

    def set_https_settings(enable_cookie = true)
      gateway_backend_http_settings_prop = ApplicationGatewayBackendHttpSettingsPropertiesFormat.new
      gateway_backend_http_settings_prop.port = 80
      gateway_backend_http_settings_prop.protocol = ApplicationGatewayProtocol::Http
      if enable_cookie
        gateway_backend_http_settings_prop.cookie_based_affinity = ApplicationGatewayCookieBasedAffinity::Enabled
      else
        gateway_backend_http_settings_prop.cookie_based_affinity = ApplicationGatewayCookieBasedAffinity::Disabled
      end

      gateway_backend_http_settings = ApplicationGatewayBackendHttpSettings.new
      gateway_backend_http_settings.name = @configurations['gateway']['http_settings_name']
      gateway_backend_http_settings.id = get_attribute_id('backendHttpSettingsCollection', gateway_backend_http_settings.name)
      gateway_backend_http_settings.properties = gateway_backend_http_settings_prop

      @gateway_attributes[:https_settings] = gateway_backend_http_settings
    end

    def set_gateway_port(ssl_certificate_exist)
      gateway_front_port_prop = ApplicationGatewayFrontendPortPropertiesFormat.new
      gateway_front_port_prop.port = ssl_certificate_exist ? 443 : 80
      gateway_front_port = ApplicationGatewayFrontendPort.new
      gateway_front_port.name = @configurations['gateway']['gateway_front_port_name']
      gateway_front_port.id = get_attribute_id('frontendPorts', gateway_front_port.name)
      gateway_front_port.properties = gateway_front_port_prop

      @gateway_attributes[:gateway_port] = gateway_front_port
    end

    def set_frontend_ip_config(public_ip, subnet)
      frontend_ip_config_prop = ApplicationGatewayFrontendIpConfigurationPropertiesFormat.new
      if public_ip.nil?
        frontend_ip_config_prop.subnet = subnet
        frontend_ip_config_prop.private_ipallocation_method = IpAllocationMethod::Dynamic
      else
        frontend_ip_config_prop.public_ipaddress = public_ip
      end
      frontend_ip_config = ApplicationGatewayFrontendIpConfiguration.new
      frontend_ip_config.name = @configurations['gateway']['frontend_ip_config_name']
      frontend_ip_config.id = get_attribute_id('frontendIPConfigurations',frontend_ip_config.name)
      frontend_ip_config.properties = frontend_ip_config_prop

      @gateway_attributes[:frontend_ip_config] = frontend_ip_config
    end

    def set_ssl_certificate(data, password)
      ssl_certificate_prop = ApplicationGatewaySslCertificatePropertiesFormat.new
      ssl_certificate_prop.data = data
      ssl_certificate_prop.password = password
      ssl_certificate = ApplicationGatewaySslCertificate.new
      ssl_certificate.name = @configurations['gateway']['ssl_certificate_name']
      ssl_certificate.id = get_attribute_id('sslCertificates',ssl_certificate.name)
      ssl_certificate.properties = ssl_certificate_prop

      @gateway_attributes[:ssl_certificate] = ssl_certificate
    end

    def set_listener(certificate_exist)
      gateway_listener_prop = ApplicationGatewayHttpListenerPropertiesFormat.new
      gateway_listener_prop.protocol = certificate_exist ? ApplicationGatewayProtocol::Https : ApplicationGatewayProtocol::Http
      gateway_listener_prop.frontend_ip_configuration = @gateway_attributes[:frontend_ip_config]
      gateway_listener_prop.frontend_port = @gateway_attributes[:gateway_port]
      gateway_listener_prop.ssl_certificate = @gateway_attributes[:ssl_certificate]

      gateway_listener = ApplicationGatewayHttpListener.new
      gateway_listener.name = @configurations['gateway']['gateway_listener_name']
      gateway_listener.id = get_attribute_id('httpListeners',gateway_listener.name)
      gateway_listener.properties = gateway_listener_prop

      @gateway_attributes[:listener] = gateway_listener
    end

    def set_gateway_request_routing_rule
      gateway_request_route_rule_prop = ApplicationGatewayRequestRoutingRulePropertiesFormat.new
      gateway_request_route_rule_prop.rule_type = ApplicationGatewayRequestRoutingRuleType::Basic
      gateway_request_route_rule_prop.backend_http_settings = @gateway_attributes[:https_settings]
      gateway_request_route_rule_prop.http_listener = @gateway_attributes[:listener]
      gateway_request_route_rule_prop.backend_address_pool = @gateway_attributes[:backend_address_pool]

      gateway_request_route_rule = ApplicationGatewayRequestRoutingRule.new
      gateway_request_route_rule.name = @configurations['gateway']['gateway_request_route_rule_name']
      gateway_request_route_rule.properties = gateway_request_route_rule_prop

      @gateway_attributes[:gateway_request_routing_rule] = gateway_request_route_rule
    end

    def set_gateway_sku(sku_name)
      gateway_sku = ApplicationGatewaySku.new
      case sku_name.downcase
      when 'small'
        gateway_sku.name = ApplicationGatewaySkuName::StandardSmall
      when 'medium'
        gateway_sku.name = ApplicationGatewaySkuName::StandardMedium
      when 'large'
        gateway_sku.name = ApplicationGatewaySkuName::StandardLarge
      else
        gateway_sku.name = ApplicationGatewaySkuName::StandardMedium
      end

      gateway_sku.tier = ApplicationGatewayTier::Standard
      gateway_sku.capacity = 2

      @gateway_attributes[:gateway_sku] = gateway_sku
    end

    def get_gateway(location, certificate_exist)
      gateway_prop = ApplicationGatewayPropertiesFormat.new
      gateway_prop.backend_address_pools = [@gateway_attributes[:backend_address_pool]]
      gateway_prop.backend_http_settings_collection = [@gateway_attributes[:https_settings]]
      gateway_prop.frontend_ip_configurations = [@gateway_attributes[:frontend_ip_config]]
      gateway_prop.gateway_ip_configurations = [@gateway_attributes[:gateway_configuration]]
      gateway_prop.frontend_ports = [@gateway_attributes[:gateway_port]]
      gateway_prop.http_listeners = [@gateway_attributes[:listener]]
      gateway_prop.request_routing_rules = [@gateway_attributes[:gateway_request_routing_rule]]
      gateway_prop.sku = @gateway_attributes[:gateway_sku]
      if certificate_exist
        gateway_prop.ssl_certificates = [@gateway_attributes[:ssl_certificate]]
      end
      gateway = ApplicationGateway.new
      gateway.name = @ag_name
      gateway.location = location
      gateway.properties = gateway_prop

      gateway
    end

    def create_or_update(gateway)
      begin
        promise = @client.application_gateways.create_or_update(@resource_group_name, @ag_name, gateway)

        response = promise.value!
        response.body
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("FATAL ERROR creating Gateway....: #{e.body}")
      rescue => e
        OOLog.fatal("Gateway creation error....: #{e.message}")
      end
    end

    def delete
      begin
        promise = @client.application_gateways.delete(@resource_group_name, @ag_name)
        response = promise.value!
        response.body
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("FATAL ERROR deleting Gateway....: #{e.body}")
      rescue => e
        OOLog.fatal("Gateway deleting error....: #{e.body}")
      end
    end
  end
end
