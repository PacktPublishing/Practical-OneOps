require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class PoolRequest < BaseRequest

  def create_lbaas_pool(listener_id, protocol, lb_algorithm, options = {})
    data = {
        'pool' => {
            'listener_id'   => listener_id,
            'protocol'      => protocol,
            'lb_algorithm'  => lb_algorithm
        }
    }

    optional_parameters = [:name, :description, :admin_state_up, :session_persistence, :tenant_id]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['pool'][key] = options[key]
    end

    request(
        :body    => Fog::JSON.encode(data),
        :expects => [201],
        :method  => 'POST',
        :path    => '/lbaas/pools'
    )
  end

  def update_lbaas_pool(pool_id, options = {})
    data = { 'pool' => {} }

    optional_parameters = [:name, :description, :admin_state_up, :lb_algorithm, :session_persistence]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['pool'][key] = options[key]
    end
    request(
        :body     => Fog::JSON.encode(data),
        :expects  => 200,
        :method   => 'PUT',
        :path    => "/lbaas/pools/#{pool_id}"
    )
  end

  def list_lbaas_pools(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/lbaas/pools',
        :query   => filters
    )
  end

  def get_lbaas_pool(pool_id)
    request(
        :expects => [200,404],
        :method  => 'GET',
        :path    => "/lbaas/pools/#{pool_id}"
    )
  end

  def delete_lbaas_pool(pool_id)
    request(
        :expects => 204,
        :method  => 'DELETE',
        :path    => "/lbaas/pools/#{pool_id}"
    )
  end
end
