require 'fog'
require 'uri'

class TenantModel

  def initialize(endpoint, username, password, vsphere_expected_pubkey_hash)
    fail ArgumentError, 'endpoint is nil' if endpoint.nil?
    fail ArgumentError, 'username is nil' if username.nil?
    fail ArgumentError, 'password is nil' if password.nil?
    fail ArgumentError, 'vsphere_expected_pubkey_hash is nil' if vsphere_expected_pubkey_hash.nil?

    @endpoint = endpoint
    @username = username
    @password = password
    @vsphere_expected_pubkey_hash = vsphere_expected_pubkey_hash
  end

  attr_reader :endpoint, :username, :password, :vsphere_expected_pubkey_hash

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
    object = {}
    object['endpoint'] = @endpoint
    object['username'] = @username
    object['password'] = @password
    object['vsphere_expected_pubkey_hash'] = @vsphere_expected_pubkey_hash

    object
  end

  def get_compute_provider
    compute_provider=Fog::Compute::Vsphere.new(:vsphere_server => @endpoint,
                             :vsphere_username => @username,
                             :vsphere_password=> @password,
                             :vsphere_expected_pubkey_hash => @vsphere_expected_pubkey_hash)
    return compute_provider
  end
end
