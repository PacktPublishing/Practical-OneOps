require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class SubnetRequest < BaseRequest

  def list_subnets(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/subnets',
        :query   => filters
    )
  end

  def get_subnet(pool_id)
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => "/subnets/#{pool_id}"
    )
  end

end
