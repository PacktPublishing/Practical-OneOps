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

class LoadbalancerManager

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    loadbalancer_request = LoadbalancerRequest.new(tenant)
    @loadbalancer_dao = LoadbalancerDao.new(loadbalancer_request)
    @listener_dao = ListenerDao.new(tenant)
    @pool_dao = PoolDao.new(tenant)
    @member_dao = MemberDao.new(tenant)
    @health_monitor_dao = HealthMonitorDao.new(tenant)
  end

  def create_loadbalancer(loadbalancer)
    is_exist = @loadbalancer_dao.is_exist_loadbalancer(loadbalancer.label.name)

    if !is_exist
      loadbalancer_id = @loadbalancer_dao.create_loadbalancer(loadbalancer)

      if !loadbalancer_id.nil?
        loadbalancer.listeners.each do |listener|
          listener_id = @listener_dao.create_listener(loadbalancer_id, listener)
          pool_id = @pool_dao.create_pool(loadbalancer_id, listener_id, listener.pool)
          listener.pool.members.each do |member|
            @member_dao.create_member(loadbalancer_id, pool_id, member)
          end
          @health_monitor_dao.create_health_monitor(loadbalancer_id, pool_id, listener.pool.health_monitor)
        end
      end
    else
      raise("Cannot create Loadbalancer #{loadbalancer.label.name} already exist.")
    end

    return loadbalancer_id
  end

  def get_loadbalancer(loadbalancer_id)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    if loadbalancer_id =~ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      loadbalancer = @loadbalancer_dao.get_loadbalancer(loadbalancer_id)
    else
      lb_id = @loadbalancer_dao.get_loadbalancer_id(loadbalancer_id)
      loadbalancer = @loadbalancer_dao.get_loadbalancer(lb_id)
    end

    listeners = Array.new()
    loadbalancer.listeners.each do |listener|
      listener = @listener_dao.get_listener(listener['id'])
      listener.pool = @pool_dao.get_pool(listener.default_pool_id) if !listener.default_pool_id.nil?
      listener.pool.members = @member_dao.get_members(listener.pool.id) if !listener.pool.nil? && !listener.pool.id.nil?
      listener.pool.health_monitor = @health_monitor_dao.get_health_monitor(listener.pool.healthmonitor_id) if !listener.pool.nil? && !listener.pool.healthmonitor_id.nil?
      listeners.push(listener)
    end
    loadbalancer.listeners = listeners

    return loadbalancer
  end


  def delete_loadbalancer(loadbalancer_name)
    fail ArgumentError, 'loadbalancer is nil' if loadbalancer_name.nil?

    loadbalancer_id = @loadbalancer_dao.get_loadbalancer_id(loadbalancer_name)
    loadbalancer = get_loadbalancer(loadbalancer_id)
    loadbalancer.listeners.each do |listener|
      if !listener.pool.healthmonitor_id.nil?
        raise 'failed to delete health monitor' if @health_monitor_dao.delete_health_monitor(listener.pool.healthmonitor_id, loadbalancer.id) == false
      end
      if !listener.pool.id.nil?
        raise 'failed to delete pool' if @pool_dao.delete_pool(listener.pool.id, loadbalancer.id) == false
      end
      raise 'failed to delete listener' if @listener_dao.delete_listener(listener.id, loadbalancer.id) == false
    end

    if !@loadbalancer_dao.delete_loadbalancer(loadbalancer.id)
      raise 'failed to delete loadbalancer'
    end

    return true
  end

end




