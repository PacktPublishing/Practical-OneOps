require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class LoadbalancerRequest < BaseRequest

  def create_lbaas_loadbalancer(vip_subnet_id, options = {})
    data = {
      'loadbalancer' => {
          'vip_subnet_id'   => vip_subnet_id
        }
    }

    optional_parameters = [:name, :description, :admin_state_up, :provider, :tenant_id, :vip_address]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['loadbalancer'][key] = options[key]
    end

    request(
        :body    => Fog::JSON.encode(data),
        :expects => [201],
        :method  => 'POST',
        :path    => '/lbaas/loadbalancers',
    )
  end

  def update_lbaas_loadbalancer(loadbalancer_id, options = {})
    data = { 'loadbalancer' => {} }

    optional_parameters = [:name, :description, :admin_state_up]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['loadbalancer'][key] = options[key]
    end

    request(
        :body     => Fog::JSON.encode(data),
        :expects  => 200,
        :method   => 'PUT',
        :path    => "/lbaas/loadbalancers/#{loadbalancer_id}"
    )
  end

  def list_lbaas_loadbalancers(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/lbaas/loadbalancers',
        :query   => filters
    )
  end

  def get_lbaas_loadbalancer(loadbalancer_id)
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => "/lbaas/loadbalancers/#{loadbalancer_id}"
    )
  end

  def delete_lbaas_loadbalancer(loadbalancer_id)
    request(
        :expects => 204,
        :method  => 'DELETE',
        :path    => "/lbaas/loadbalancers/#{loadbalancer_id}"
    )
  end

  def get_service_provider
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/service-providers'
    )
  end
end
