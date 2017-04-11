require File.expand_path('../../libraries/data_access/lbaas/loadbalancer_dao', __FILE__)
require File.expand_path('../../libraries/data_access/lbaas/listener_dao', __FILE__)
require File.expand_path('../../libraries/data_access/lbaas/pool_dao', __FILE__)
require File.expand_path('../../libraries/data_access/lbaas/member_dao', __FILE__)
require File.expand_path('../../libraries/data_access/lbaas/health_monitor_dao', __FILE__)
require File.expand_path('../../libraries/requests/lbaas/loadbalancer_request', __FILE__)
require File.expand_path('../../libraries/requests/lbaas/listener_request', __FILE__)
require File.expand_path('../../libraries/requests/lbaas/pool_request', __FILE__)
require File.expand_path('../../libraries/requests/lbaas/member_request', __FILE__)
require File.expand_path('../../libraries/requests/lbaas/health_monitor_request', __FILE__)


class MemberManager

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?
    @member_dao = MemberDao.new(tenant)

  end

  def delete_member(pool_id, member_id)
    Chef::Log.info("deleting member from pool_id #{pool_id}")
    return @member_dao.delete_member(pool_id, member_id)
  end

  def get_members(pool_id)
    Chef::Log.info("getting member list for pool_id #{pool_id}")
    return @member_dao.get_members(pool_id)
  end

  def is_member_exist(pool_id, ip_address)

    member_list = @member_dao.get_members(pool_id)
    member_list.each do | member|
      if member.address == ip_address
        return true
      end
    end
    return false
  end

  def add_member(lb_id, pool_id, member)
    Chef::Log.info("adding member to pool_id #{pool_id}")
    return @member_dao.create_member(lb_id, pool_id, member)
  end

end