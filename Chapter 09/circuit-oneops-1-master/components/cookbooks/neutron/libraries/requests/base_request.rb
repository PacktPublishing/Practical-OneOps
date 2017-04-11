require 'rest-client'
require 'json'
require 'fog'
require 'fog/openstack/core'


class BaseRequest
  NEUTRON_PORT = '9696'
  PERSISTENT = false
  CONNECTION_OPTIONS = {}

  def initialize(tenant)
    @@tenant = tenant
    @@scheme = tenant.scheme
    @@host = tenant.host
    @@port = tenant.port
    @@tenant_name = tenant.tenant_name
    @@user = tenant.username
    @@password = tenant.password
    @@connection = Fog::Core::Connection.new("#{@@scheme}://#{@@host}:#{NEUTRON_PORT}", PERSISTENT, CONNECTION_OPTIONS)
  end

  def get_token
    resource_url = @@scheme + '://' + @@host + ':' + @@port + '/v2.0/tokens'
    payload = '{"auth": {"tenantName": "' + @@tenant_name + '", "passwordCredentials": {"username": "' + @@user + '", "password": "' + @@password + '"}}}'

    begin
      response = RestClient.post(
          resource_url,
          payload,
          {
              :accept => :json,
              :content_type => :json,
          }
      )
    rescue => e
      puts('ERROR: get_token status code - ' + e.to_s)
      raise(e.response)
    end

    return JSON.parse(response)['access']['token']['id']
  end

  def request (params)
    begin
      response = @@connection.request(params.merge({:headers  => {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-Auth-Token' => get_token
      }.merge!(params[:headers] || {}),
        :path     => "v2.0#{params[:path]}"}))
    rescue => e
      raise('ERROR - ' + e.to_s)
    end

    return response.data
  end

  def wait(loadbalancer_id)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    time_to_live = 300
    start_time = Time.now
    loadbalancer_request = LoadbalancerRequest.new(@@tenant)

    loop do
      response = loadbalancer_request.get_lbaas_loadbalancer(loadbalancer_id)
      provisioning_status = JSON.parse(response[:body])['loadbalancer']['provisioning_status']
      if provisioning_status == 'ACTIVE' || provisioning_status == 'ERROR'
        break
      end
      sleep(10)
      break if Time.now > start_time + time_to_live
    end

    return self
  end

end
