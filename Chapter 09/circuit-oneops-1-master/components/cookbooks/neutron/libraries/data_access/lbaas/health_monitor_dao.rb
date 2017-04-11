require File.expand_path('../../../../libraries/requests/lbaas/health_monitor_request', __FILE__)
require File.expand_path('../../../../libraries/models/lbaas/health_monitor_model', __FILE__)

class HealthMonitorDao

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @health_monitor_request = HealthMonitorRequest.new(tenant)
  end

  def create_health_monitor(loadbalancer_id, pool_id, health_monitor)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?
    fail ArgumentError, 'health_monitor is nil' if health_monitor.nil?

    options = health_monitor.serialize_optional_parameters
    response = @health_monitor_request.wait(loadbalancer_id).
        create_lbaas_health_monitor(pool_id, health_monitor.type, health_monitor.delay,
                                    health_monitor.timeout, health_monitor.max_retries, options)
    if response[:'status'] == 201
      healthmonitor_id = JSON.parse(response[:body])['healthmonitor']['id']
    end

    return healthmonitor_id
  end

  def get_health_monitor(healthmonitor_id)
    fail ArgumentError, 'healthmonitor_id is nil' if healthmonitor_id.nil? || healthmonitor_id.empty?

    response = @health_monitor_request.get_lbaas_health_monitor(healthmonitor_id)
    if response[:status] == 200

      health_monitor_dto = JSON.parse(response[:body])['healthmonitor']
      health_monitor = HealthMonitorModel.new(health_monitor_dto['type'], health_monitor_dto['delay'],
                                              health_monitor_dto['timeout'], health_monitor_dto['max_retries'], health_monitor_dto['tenant_id'],
                                              health_monitor_dto['id'], health_monitor_dto['pools'][0]['id'])
      health_monitor.http_method = (health_monitor_dto['http_method'])
      health_monitor.url_path = (health_monitor_dto['url_path'])
      health_monitor.expected_codes = (health_monitor_dto['expected_codes'])
      health_monitor.admin_state_up = (health_monitor_dto['admin_state_up'])

      return health_monitor
    end
  end

  def delete_health_monitor(healthmonitor_id, loadbalancer_id)
    fail ArgumentError, 'healthmonitor_id is nil' if healthmonitor_id.nil? || healthmonitor_id.empty?
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    response = @health_monitor_request.wait(loadbalancer_id).delete_lbaas_health_monitor(healthmonitor_id)

    return response[:'status'] == 204 || response[:'status'] == 404 ? true : false
  end

  def update_health_monitor(loadbalancer_id, health_monitor_id, health_monitor)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'health_monitor is nil' if health_monitor.nil?

    options = health_monitor.serialize_optional_parameters
    response = @health_monitor_request.wait(loadbalancer_id).
        update_lbaas_health_monitor(health_monitor_id, options)
    if response[:'status'] == 204 || response[:'status'] == 200
      healthmonitor_id = JSON.parse(response[:body])['healthmonitor']['id']
    end
    return healthmonitor_id
  end

end