require File.expand_path('../base_model', __FILE__)
require File.expand_path('../label_model', __FILE__)
require File.expand_path('../session_persistence_model', __FILE__)

class PoolModel < BaseModel
  module Protocol
    HTTP = 'HTTP'
    HTTPS = 'HTTPS'
    TCP = 'TCP'
  end

  module LbAlgorthm
    ROUND_ROBIN = 'ROUND_ROBIN'
    LEAST_CONNECTIONS = 'LEAST_CONNECTIONS'
    SOURCE_IP = 'SOURCE_IP'
  end

  def initialize(protocol, lb_algorithm, tenant_id = nil, listener_id = nil, id = nil, healthmonitor_id = nil, provisioning_status = nil, operating_status = nil)
    fail ArgumentError, 'protocol is invalid' if protocol.nil? || protocol.empty?
    fail ArgumentError, 'lb_algorithm is invalid' if lb_algorithm.nil? || lb_algorithm.empty?

    super()
    @protocol = validate_protocol(protocol)
    @lb_algorithm = validate_lb_algorithm(lb_algorithm)
    @tenant_id = tenant_id
    @listener_id = listener_id
    @id = id
    @healthmonitor_id = healthmonitor_id
    @provisioning_status = provisioning_status
    @operating_status = operating_status
    @label = LabelModel.new
    @session_persistence = nil
  end

  attr_reader :protocol, :lb_algorithm, :tenant_id, :listener_id, :id, :healthmonitor_id, :provisioning_status,
              :operating_status, :members, :health_monitor, :session_persistence

  def lb_algorithm=(lb_algorithm)
    @lb_algorithm = validate_lb_algorithm(lb_algorithm)
  end

  def session_persistence=(session_persistence)
    if session_persistence.class == Hash || session_persistence.nil?
      @session_persistence = session_persistence
    elsif session_persistence == "none"
      @session_persistence = nil
    else
      fail ArgumentError, 'session_persistence is invalid'
    end
  end

  def members=(members)
    @members = members
  end

  def health_monitor=(health_monitor)
    @health_monitor = health_monitor
  end

  def serialize_optional_parameters
    options = {}
    options[:name] = @label.name
    options[:description] = @label.description
    options[:admin_state_up] = admin_state_up
    options[:lb_algorithm] = lb_algorithm
    options[:session_persistence] = session_persistence
    options[:health_monitor] = health_monitor
    if !@tenant_id.nil? then options[:tenant_id] = @tenant_id end

    return options
  end

  def validate_protocol(protocol)
    protocol_upcase = protocol.upcase
    if protocol_upcase == Protocol::HTTP || protocol_upcase == Protocol::HTTPS || protocol_upcase == Protocol::TCP
      return protocol_upcase
    else
      fail ArgumentError, 'protocol is invalid'
    end
  end
  private :validate_protocol

  def validate_lb_algorithm(lb_algorithm)
    two_word_pascalcase = '([A-Z][a-z0-9]+){2,}'

    if lb_algorithm.match(two_word_pascalcase)
      lb_algorithm_upcase = lb_algorithm.underscore.upcase
    elsif lb_algorithm.count(' ') > 0
      lb_algorithm_upcase = lb_algorithm.tr(' ', '_').upcase
    elsif lb_algorithm.include? 'round'
        lb_algorithm_upcase = 'ROUND_ROBIN'
    elsif lb_algorithm.include? 'least'
        lb_algorithm_upcase = 'LEAST_CONNECTIONS'
    elsif lb_algorithm.include? 'source'
        lb_algorithm_upcase = 'SOURCE_IP'
    else
      lb_algorithm_upcase = lb_algorithm
    end

    if lb_algorithm_upcase == LbAlgorthm::ROUND_ROBIN || lb_algorithm_upcase == LbAlgorthm::LEAST_CONNECTIONS || lb_algorithm_upcase == LbAlgorthm::SOURCE_IP
      return lb_algorithm_upcase
    else
      fail ArgumentError, 'lb_algorithm is invalid'
    end
  end
  private :validate_lb_algorithm

end

