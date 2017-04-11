require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class MemberRequest < BaseRequest

  def create_lbaas_member(pool_id, ip_address, port, subnet_id, options = {})
    data = {
        'member' => {
            'address'       => ip_address,
            'protocol_port' => port,
            'subnet_id' => subnet_id
        }
    }

    optional_parameters = [:name, :admin_state_up, :weight, :tenant_id]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['member'][key] = options[key]
    end

    request(
        :body    => Fog::JSON.encode(data),
        :expects => [201],
        :method  => 'POST',
        :path    => "/lbaas/pools/#{pool_id}/members"
    )
  end

  def update_lbaas_member(pool_id, member_id, options = {})
    data = { 'member' => {} }

    optional_parameters = [:admin_state_up, :weight]
    optional_parameters.select{ |o| options.key?(o) }.each do |key|
      data['member'][key] = options[key]
    end

    request(
        :body     => Fog::JSON.encode(data),
        :expects  => 200,
        :method   => 'PUT',
        :path    => "/lbaas/pools/#{pool_id}/members/#{member_id}"
    )
  end

  def list_lbaas_members(pool_id, filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => "/lbaas/pools/#{pool_id}/members",
        :query   => filters
    )
  end

  def get_lbaas_member(pool_id, member_id)
    request(
        :expects => [200,404],
        :method  => 'GET',
        :path    => "/lbaas/pools/#{pool_id}/members/#{member_id}"
    )
  end

  def delete_lbaas_member(pool_id, member_id)
    request(
        :expects => 204,
        :method  => 'DELETE',
        :path    => "/lbaas/pools/#{pool_id}/members/#{member_id}"
    )
  end
end
