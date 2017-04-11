require File.expand_path('../../../../libraries/requests/lbaas/pool_request', __FILE__)
require File.expand_path('../../../../libraries/models/lbaas/pool_model', __FILE__)

class PoolDao

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @pool_request = PoolRequest.new(tenant)
  end

  def create_pool(loadbalancer_id, listener_id, pool)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'listener_id is nil' if listener_id.nil? || listener_id.empty?
    fail ArgumentError, 'pool is nil' if pool.nil?

    options = pool.serialize_optional_parameters
    response = @pool_request.wait(loadbalancer_id).create_lbaas_pool(listener_id, pool.protocol, pool.lb_algorithm, options)
    if response[:'status'] == 201
      pool_id = JSON.parse(response[:body])['pool']['id']
    end

    return pool_id
  end

  def get_pool(pool_id)
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?

    response = @pool_request.get_lbaas_pool(pool_id)
    if response[:status] == 200
      pool_dto = JSON.parse(response[:body])['pool']
      pool = PoolModel.new(pool_dto['protocol'], pool_dto['lb_algorithm'], pool_dto['tenant_id'],
                           pool_dto['listeners'][0]['id'], pool_dto['id'], pool_dto['healthmonitor_id'],
                           pool_dto['provisioning_status'], pool_dto['operating_status'])
      pool.label.name = (pool_dto['name'])
      pool.label.description = (pool_dto['description'])
      pool.admin_state_up = (pool_dto['admin_state_up'])
      pool.session_persistence = (pool_dto['session_persistence'])
      pool.members = (pool_dto['members'])

      return pool
    end
  end

  def delete_pool(pool_id, loadbalancer_id)
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    response = @pool_request.wait(loadbalancer_id).delete_lbaas_pool(pool_id)

    return response[:'status'] == 204 || response[:'status'] == 404 ? true : false
  end

  def update_pool(loadbalancer_id, listener_id, pool_id, pool)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'listener_id is nil' if listener_id.nil? || listener_id.empty?
    fail ArgumentError, 'pool is nil' if pool.nil?

    options = pool.serialize_optional_parameters

    Chef::Log.info ("options :")
    Chef::Log.info (options.inspect)
    response = @pool_request.wait(loadbalancer_id).update_lbaas_pool(pool_id, options)
    if response[:'status'] == 204 || response[:'status'] == 200
      pool_id = JSON.parse(response[:body])['pool']['id']
    end

    return pool_id
  end


end