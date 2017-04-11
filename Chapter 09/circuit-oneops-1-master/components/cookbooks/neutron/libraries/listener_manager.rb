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
class ListenerManager

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @listener_dao = ListenerDao.new(tenant)
    @pool_dao = PoolDao.new(tenant)
    @member_dao = MemberDao.new(tenant)
    @health_monitor_dao = HealthMonitorDao.new(tenant)

  end

  def add_listener(loadbalancer_id, listener)
    listener_id = @listener_dao.create_listener(loadbalancer_id, listener)
    pool_id = @pool_dao.create_pool(loadbalancer_id, listener_id, listener.pool)
    listener.pool.members.each do |member|
      @member_dao.create_member(loadbalancer_id, pool_id, member)
    end
    @health_monitor_dao.create_health_monitor(loadbalancer_id, pool_id, listener.pool.health_monitor)
  end


  def delete_listener(loadbalancer_id, listener)

    if !listener.pool.nil? && !listener.pool.healthmonitor_id.nil?
      if @health_monitor_dao.get_health_monitor(listener.pool.healthmonitor_id) != nil
        raise 'failed to delete health monitor' if @health_monitor_dao.delete_health_monitor(listener.pool.healthmonitor_id, loadbalancer_id) == false
      end
    end
    if !listener.pool.nil? && !listener.pool.id.nil?
      if @pool_dao.get_pool(listener.pool.id) != nil
        raise 'failed to delete pool' if @pool_dao.delete_pool(listener.pool.id, loadbalancer_id) == false
      end
    end
    if @listener_dao.is_listener_exist(listener.id)
      if @listener_dao.delete_listener(listener.id, loadbalancer_id) == false
        raise 'failed to delete listener'
      end
    end
  end
end