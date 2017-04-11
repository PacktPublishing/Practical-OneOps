class TrafficManager
  module ProfileStatus
    ENABLED = 'Enabled'
    DISABLED = 'Disabled'
  end

  module RoutingMethod
    PERFORMANCE = 'Performance'
    WEIGHTED = 'Weighted'
    PRIORITY = 'Priority'
  end

  GLOBAL = 'global'

  def initialize(routing_method, dns_config, monitor_config, endpoints)
    fail ArgumentError, 'routing_method is nil' if routing_method.nil?
    fail ArgumentError, 'dns_config is nil' if dns_config.nil?
    fail ArgumentError, 'monitor_config is nil' if monitor_config.nil?
    fail ArgumentError, 'endpoints is nil' if endpoints.nil?

    @routing_method = routing_method
    @dns_config = dns_config
    @monitor_config = monitor_config
    @endpoints = endpoints
    @profile_status = ProfileStatus::ENABLED
    @location = GLOBAL
  end

  attr_reader :routing_method, :dns_config, :monitor_config, :profile_status, :location

  def set_profile_status=(profile_status)
    @profile_status = profile_status
  end

  def serialize_object
    properties = {}
    properties['profileStatus'] = @profile_status
    properties['trafficRoutingMethod'] = @routing_method
    properties['dnsConfig'] = @dns_config.serialize_object
    properties['monitorConfig'] = @monitor_config.serialize_object
    properties['endpoints'] = serialize_endpoints

    payload = {}
    payload['location'] = GLOBAL
    payload['tags'] = {}
    payload['properties'] = properties

    payload
  end

  def serialize_endpoints
    unless @endpoints.nil?
      serializedArray = []
      @endpoints.each do |endpoint|
        unless endpoint.nil?
          element = endpoint.serialize_object
        end
        serializedArray.push(element)
      end
    end
    return serializedArray
  end

end

