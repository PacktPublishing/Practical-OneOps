
class SessionPersistenceModel
  module Type
    SOURCE_IP = 'SOURCE_IP'
    HTTP_COOKIE = 'HTTP_COOKIE'
    APP_COOKIE = 'APP_COOKIE'
  end

  def initialize(type)
    fail ArgumentError, 'type is invalid' if type.nil? || type.empty?

    @type = validate_type(type)
    @cookie_name = nil
  end

  attr_reader :type, :cookie_name

  def cookie_name=(cookie_name)
    if @type == Type::APP_COOKIE
      @cookie_name = cookie_name
    else
      fail ArgumentError, 'cookie_name is invalid, session type must be APP_COOKIE'
    end
  end

  def serialize_optional_parameters
    options = {}
    options[:type] = @type
    if !@cookie_name.nil? then options[:cookie_name] = @cookie_name end

    return options
  end

  def validate_type(type)
    type_upcase = type.upcase
    if type_upcase.start_with? 'SOURCE'
      type_upcase = 'SOURCE_IP'
    elsif type_upcase.start_with? 'COOKIE'
      type_upcase = 'HTTP_COOKIE'
    end

    if type_upcase == Type::SOURCE_IP || type_upcase == Type::HTTP_COOKIE || type_upcase == Type::APP_COOKIE
      return type_upcase
    else
      fail ArgumentError, 'session_persistence_type is invalid'
    end
  end
  private :validate_type

end