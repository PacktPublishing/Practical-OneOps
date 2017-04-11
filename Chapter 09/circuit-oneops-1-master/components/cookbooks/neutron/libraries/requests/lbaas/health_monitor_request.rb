require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class HealthMonitorRequest < BaseRequest

  def create_lbaas_health_monitor(pool_id, type, delay, timeout, max_retries, options = {})
    data = {
        'healthmonitor' => {
            'pool_id'     => pool_id,
            'type'        => type,
            'delay'       => delay,
            'timeout'     => timeout,
            'max_retries' => max_retries
        }
    }

    optional_parameters = [:name, :http_method, :url_path, :expected_codes, :admin_state_up, :tenant_id]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['healthmonitor'][key] = options[key]
    end

    request(
        :body    => Fog::JSON.encode(data),
        :expects => [201],
        :method  => 'POST',
        :path    => '/lbaas/healthmonitors'
    )
  end

  def update_lbaas_health_monitor(healthmonitor_id, options = {})
    data = { 'healthmonitor' => {} }

    optional_parameters = [:delay, :timeout, :max_retries, :http_method, :url_path, :expected_codes, :admin_state_up]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['healthmonitor'][key] = options[key]
    end
    request(
        :body     => Fog::JSON.encode(data),
        :expects  => 200,
        :method   => 'PUT',
        :path    => "/lbaas/healthmonitors/#{healthmonitor_id}"
    )
  end

  def list_lbaas_health_monitors(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/lbaas/healthmonitors',
        :query   => filters
    )
  end

  def get_lbaas_health_monitor(healthmonitor_id)
    request(
        :expects => [200,404],
        :method  => 'GET',
        :path    => "/lbaas/healthmonitors/#{healthmonitor_id}"
    )
  end

  def delete_lbaas_health_monitor(healthmonitor_id)
    request(
        :expects => 204,
        :method  => 'DELETE',
        :path    => "/lbaas/healthmonitors/#{healthmonitor_id}"
    )
  end

end
