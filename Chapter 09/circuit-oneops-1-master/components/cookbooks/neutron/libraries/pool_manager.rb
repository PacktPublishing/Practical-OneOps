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
class PoolManager
  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @pool_dao = PoolDao.new(tenant)
    @member_dao = MemberDao.new(tenant)
    @health_monitor_dao = HealthMonitorDao.new(tenant)

  end

  def update_pool(loadbalancer_id, listener_id, pool_id, pool)
    if @pool_dao.get_pool(pool_id) != nil
      @pool_dao.update_pool(loadbalancer_id,listener_id,pool_id,pool)
    end
  end
end