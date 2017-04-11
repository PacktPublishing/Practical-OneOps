require 'uri'

class TenantModel #todo this class needs validation

  def initialize(endpoint, tenant_name, username, password)
    fail ArgumentError, 'endpoint is nil' if endpoint.nil?
    fail ArgumentError, 'tenantName is nil' if tenant_name.nil?
    fail ArgumentError, 'username is nil' if username.nil?
    fail ArgumentError, 'password is nil' if password.nil?

    @endpoint = endpoint
    @tenant_name = tenant_name
    @username = username
    @password = password
  end

  attr_reader :tenant_name, :username, :password

  def scheme
    uri = URI.parse(@endpoint)
    scheme = uri.scheme
    @scheme = scheme
  end

  def host
    @host = URI.parse(@endpoint).host
  end

  def port
    @port = URI.parse(@endpoint).port.to_s
  end

  def serialize_object
    payload = {}
    payload['tenantName'] = @tenant_name
    payload['username'] = @username
    payload['password'] = @password

    payload
  end
end
