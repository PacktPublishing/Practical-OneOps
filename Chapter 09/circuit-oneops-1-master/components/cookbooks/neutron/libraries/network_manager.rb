require File.expand_path('../../libraries/data_access/network/subnet_dao', __FILE__)

class NetworkManager

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @subnet_dao = SubnetDao.new(tenant)
  end

  def get_subnet_id(subnet_name)
    subnet_id = @subnet_dao.get_subnet_id(subnet_name)

    return subnet_id
  end
end
