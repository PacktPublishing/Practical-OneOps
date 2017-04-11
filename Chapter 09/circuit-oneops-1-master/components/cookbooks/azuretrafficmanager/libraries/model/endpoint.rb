class EndPoint
  module Status
    ENABLED = 'Enabled'
    DISABLED = 'Disabled'
  end

  TYPE = 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'

  def initialize(name, target, location)
    fail ArgumentError, 'name is nil' if name.nil?
    fail ArgumentError, 'target is nil' if target.nil?
    fail ArgumentError, 'location is nil' if location.nil?

    @name = name
    @type = TYPE
    @target = target
    @location = location
  end

  attr_reader :name, :target, :location

  def set_endpoint_status(endpoint_status)
    @endpoint_status = endpoint_status
  end

  def set_weight(weight)
    @weight = weight
  end

  def set_priority(priority)
    @priority = priority
  end

  attr_reader :endpoint_status, :weight, :priority

  def serialize_object
    endpoint_properties = {}
    endpoint_properties['target'] = @target
    endpoint_properties['endpointStatus'] = @endpoint_status
    endpoint_properties['weight'] = @weight
    endpoint_properties['priority'] = @priority
    endpoint_properties['endpointLocation'] = @location

    endpoint = {}
    endpoint['name'] = @name
    endpoint['type'] = @type
    endpoint['properties'] = endpoint_properties
    endpoint
  end

end