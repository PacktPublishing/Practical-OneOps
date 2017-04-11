require File.expand_path('../../../../libraries/requests/lbaas/listener_request', __FILE__)
require File.expand_path('../../../../libraries/models/lbaas/listener_model', __FILE__)

class ListenerDao

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @listener_request = ListenerRequest.new(tenant)
  end

  def create_listener(loadbalancer_id, listener)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'listener is nil' if listener.nil?

    options = listener.serialize_optional_parameters
    response = @listener_request.wait(loadbalancer_id).create_lbaas_listener(loadbalancer_id, listener.protocol,
                                                                             listener.protocol_port, options)
    if response[:'status'] == 201
      listener_id = JSON.parse(response[:body])['listener']['id']
    end

    return listener_id
  end

  def get_listener(listener_id)
    fail ArgumentError, 'listener_id is nil' if listener_id.nil? || listener_id.empty?

    response = @listener_request.get_lbaas_listener(listener_id)
    if response[:status] == 200

      listener_dto = JSON.parse(response[:body])['listener']
      listener = ListenerModel.new(listener_dto['protocol'], listener_dto['protocol_port'], listener_dto['tenant_id'],
                                   listener_dto['loadbalancers'][0]['id'], listener_dto['id'], listener_dto['default_pool_id'],
                                   listener_dto['provisioning_status'], listener_dto['operating_status'])
      listener.label.name = (listener_dto['name'])
      listener.label.description = (listener_dto['description'])
      listener.connection_limit = (listener_dto['connection_limit'])
      listener.admin_state_up = (listener_dto['admin_state_up'])

      return listener
    end
  end

  def is_listener_exist(listener_id)
    fail ArgumentError, 'listener_id is nil' if listener_id.nil? || listener_id.empty?

    filters = {'id' => listener_id}
    response = @listener_request.get_lbaas_listener(listener_id)

    if response[:status] == 200
      return true
    elsif response[:status] ==  404
      return false
    end
  end

  def delete_listener(listener_id, loadbalancer_id)
    fail ArgumentError, 'listener_id is nil' if listener_id.nil? || listener_id.empty?
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    response = @listener_request.wait(loadbalancer_id).delete_lbaas_listener(listener_id)
    return response[:'status'] == 204 || response[:'status'] == 404 ? true : false
  end

  def update_listener(loadbalancer_id, listener_id, listener)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'listener is nil' if listener.nil?

    options = listener.serialize_optional_parameters
    response = @listener_request.wait(loadbalancer_id).update_lbaas_listener(listener_id,
                                                                              options)
    if response[:'status'] == 204 || response[:'status'] == 200
      listener_id = JSON.parse(response[:body])['listener']['id']
    end

    return listener_id
    end

end