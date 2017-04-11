require File.expand_path('../base_model', __FILE__)
require File.expand_path('../label_model', __FILE__)

class HealthMonitorModel < BaseModel
  module Protocol
    HTTP = 'HTTP'
    HTTPS = 'HTTPS'
    PING = 'PING'
    TCP = 'TCP'
  end

  module HttpMethod
    GET = 'GET'
    POST = 'POST'
    PUT = 'PUT'
  end

  def initialize(type, delay, timeout, max_retries, tenant_id = nil, id = nil, pool_id = nil)
    fail ArgumentError, 'type is invalid' if type.nil? || type.empty? || !is_valid_protocol(type)
    fail ArgumentError, 'delay is invalid' if delay.nil? || !delay.is_a?(Integer) || !is_valid_delay(delay)
    fail ArgumentError, 'timeout is invalid' if timeout.nil? || !timeout.is_a?(Integer) || !is_valid_timeout(timeout)
    fail ArgumentError, 'max_retries is invalid' if max_retries.nil? || !max_retries.is_a?(Integer) || !is_valid_max_retries(max_retries)

    super()
    @pool_id = pool_id
    @type = type
    @delay = delay
    @timeout = timeout
    @max_retries = max_retries
    @tenant_id = tenant_id
    @id = id

    @http_method = HttpMethod::GET
    @url_path = '/'
    @expected_codes = '200'
    @label = LabelModel.new
  end

  attr_reader :type, :delay, :timeout, :max_retries, :tenant_id, :id, :pool_id,
              :http_method, :url_path, :expected_codes

  #todo Preferred default values to provide
  #do we fail if set value is incorrect or do we provide a default. IMPORTANT: check whether delay, timeout
  #and max_retries are parameters offerred via the oneops UI.
  def delay=(delay)
    if delay.is_a?(Integer)
      if is_valid_delay(delay)
        @delay = delay
      end
    end
  end

  def timeout=(timeout)
    if timeout.is_a?(Integer)
      if is_valid_timeout(timeout)
        @timeout = timeout
      end
    end
  end

  def max_retries=(max_retries)
    fail ArgumentError, 'max_retries is nil' if max_retries.nil?
    if max_retries.is_a?(Integer)
      if is_valid_max_retries(max_retries)
        @max_retries = max_retries
      end
    end
  end

  def http_method=(http_method)
     if !http_method.nil? && !http_method.empty?
       @http_method = validate_http_method(http_method)
     end
  end

  def url_path=(url_path)
    if !url_path.nil? && !url_path.empty?
      @url_path = url_path
    end
  end

  def expected_codes=(expected_codes)
    @expected_codes = expected_codes #todo this can be a string array or a range of codes
  end

  def serialize_optional_parameters
    options = {}
    options[:name] = @label.name
    options[:http_method] = @http_method
    options[:url_path] = @url_path
    options[:expected_codes] = @expected_codes
    options[:admin_state_up] = admin_state_up
    if !@tenant_id.nil?  then options[:tenant_id] = @tenant_id end

    options
  end

  def is_valid_protocol(protocol)
    protocol_upcase = protocol.upcase
    if protocol_upcase == Protocol::HTTP || protocol_upcase == Protocol::HTTPS ||
        protocol_upcase == Protocol::PING || protocol_upcase == Protocol::TCP
      true
    else
      fail ArgumentError, 'protocol is invalid'
    end
  end
  private :is_valid_protocol

  def is_valid_delay(delay)
    if delay >= 0 && delay <= 86400
      true
    else
      fail ArgumentError, 'delay is invalid'
    end
  end
  private :is_valid_delay

  def is_valid_timeout(timeout)
    if timeout >= 0 && timeout <= 86400
      true
    else
      fail ArgumentError, 'timeout is invalid'
    end
  end
  private :is_valid_timeout

  def is_valid_max_retries(max_retries)
    if max_retries >= 1 && max_retries <= 10
      true
    else
      fail ArgumentError, 'max_retries is invalid'
    end
  end
  private :is_valid_max_retries

  def validate_http_method(http_method)
    http_method_upcase = http_method.upcase

    if http_method_upcase == HttpMethod::GET || http_method_upcase == HttpMethod::POST || http_method_upcase == HttpMethod::PUT
      return http_method_upcase
    else
      fail ArgumentError, 'http_method is invalid'
    end
  end
  private :validate_http_method

end

