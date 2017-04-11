require File.expand_path('../../../../libraries/requests/network/subnet_request', __FILE__)

class SubnetDao

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @subnet_request = SubnetRequest.new(tenant)
  end

  def get_subnet_id(subnet_name)
    fail ArgumentError, 'subnet_name is nil' if subnet_name.nil? || subnet_name.empty?

    filters = {'name' => subnet_name}
    response = @subnet_request.list_subnets(filters)
    subnets_dto = JSON.parse(response[:body])['subnets']

    return subnets_dto[0]['id']
  end

end