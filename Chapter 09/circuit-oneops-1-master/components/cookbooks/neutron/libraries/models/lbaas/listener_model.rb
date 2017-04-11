require File.expand_path('../base_model', __FILE__)
require File.expand_path('../label_model', __FILE__)

class ListenerModel < BaseModel
  module Protocol
    HTTP = 'HTTP'
    HTTPS = 'HTTPS'
    TCP = 'TCP'
  end

  def initialize(protocol, protocol_port, tenant_id = nil, loadbalancer_id = nil, id = nil, default_pool_id = nil, provisioning_status = nil, operating_status = nil)
    fail ArgumentError, 'protocol is invalid' if protocol.nil? || protocol.empty? || !is_valid_protocol(protocol)
    fail ArgumentError, 'protocol_port is invalid' if protocol_port.nil? || !is_valid_port(protocol_port)

    super()
    @protocol = protocol.upcase
    @protocol_port = protocol_port
    @tenant_id = tenant_id
    @loadbalancer_id = loadbalancer_id
    @id = id
    @default_pool_id = default_pool_id
    @provisioning_status = provisioning_status
    @operating_status = operating_status
    @connection_limit = -1
    @label = LabelModel.new
  end

  attr_reader :tenant_id, :protocol, :protocol_port, :loadbalancer_id, :id, :default_pool_id,
              :provisioning_status, :operating_status, :connection_limit, :pool

  def protocol_port=(protocol_port)
    if is_valid_port(protocol_port)
      @protocol_port = protocol_port
    end
  end

  def connection_limit=(connection_limit)
    if connection_limit.is_a?(Integer)
      @connection_limit = valid_connection_limit(connection_limit)
    else
      @connection_limit = -1
    end
  end

  def pool=(pool)
    @pool = pool
  end

  def serialize_optional_parameters
    options = {}
    options[:name] = @label.name
    options[:description] = @label.description
    options[:admin_state_up] = @admin_state_up
    options[:connection_limit] = @connection_limit
    if !@tenant_id.nil? then options[:tenant_id] = @tenant_id end

    return options
  end

  def is_valid_protocol(protocol)
    protocol_upcase = protocol.upcase
    if protocol_upcase == Protocol::HTTP || protocol_upcase == Protocol::HTTPS || protocol_upcase == Protocol::TCP
      true
    else
      fail ArgumentError, 'protocol is invalid'
    end
  end
  private :is_valid_protocol

  def valid_connection_limit(connection_limit)
    if connection_limit > 2147483647 || connection_limit < -1
      connection_limit = -1
    end
    return connection_limit
  end
  private :valid_connection_limit

end

