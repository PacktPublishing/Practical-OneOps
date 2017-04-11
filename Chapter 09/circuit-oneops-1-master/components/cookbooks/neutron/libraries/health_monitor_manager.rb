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
class HealthMonitorManager
  def initialize(tenant)
    @healthmonitor_dao = HealthMonitorDao.new(tenant)
  end

  def update_healthmonitor(lb_id,healthmonitor_id, healthmonitor)
    @healthmonitor_dao.update_health_monitor(lb_id, healthmonitor_id, healthmonitor)
  end
end