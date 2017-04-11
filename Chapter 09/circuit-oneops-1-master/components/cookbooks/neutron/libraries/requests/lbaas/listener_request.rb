require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class ListenerRequest < BaseRequest

  def create_lbaas_listener(loadbalancer_id, protocol, protocol_port, options = {})
    data = {
        'listener' => {
            'loadbalancer_id'  => loadbalancer_id,
            'protocol'         => protocol,
            'protocol_port'    => protocol_port
        }
    }

    optional_parameters = [:name, :description, :admin_state_up, :connection_limit, :tenant_id]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['listener'][key] = options[key]
    end

    request(
        :body    => Fog::JSON.encode(data),
        :expects => [201],
        :method  => 'POST',
        :path    => '/lbaas/listeners'
    )
  end

  def update_lbaas_listener(listener_id, options = {})
    data = { 'listener' => {} }

    optional_parameters = [:name, :description, :admin_state_up, :connection_limit]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['listener'][key] = options[key]
    end

    request(
        :body     => Fog::JSON.encode(data),
        :expects  => 200,
        :method   => 'PUT',
        :path    => "/lbaas/listeners/#{listener_id}"
    )
  end

  def list_lbaas_listeners(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/lbaas/listeners',
        :query   => filters
    )
  end

  def get_lbaas_listener(listener_id)
    request(
        :expects => [200,404],
        :method  => 'GET',
        :path    => "/lbaas/listeners/#{listener_id}"
    )
  end
  
  def delete_lbaas_listener(listener_id)
    request(
        :expects => 204,
        :method  => 'DELETE',
        :path    => "/lbaas/listeners/#{listener_id}"
    )
  end
end
