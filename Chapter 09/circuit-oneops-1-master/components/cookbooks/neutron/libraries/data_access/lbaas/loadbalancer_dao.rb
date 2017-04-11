require File.expand_path('../../../../libraries/models/lbaas/loadbalancer_model', __FILE__)

class LoadbalancerDao

  def initialize(loadbalancer_request)
    fail ArgumentError, 'loadbalancer_request is nil' if loadbalancer_request.nil?

    @loadbalancer_request = loadbalancer_request
  end

  def create_loadbalancer(loadbalancer)
    fail ArgumentError, 'loadbalancer is nil' if loadbalancer.nil?

    options = loadbalancer.serialize_optional_parameters
    response = @loadbalancer_request.create_lbaas_loadbalancer(loadbalancer.vip_subnet_id, options)
    if response[:'status'] == 201
      loadbalancer_id = JSON.parse(response[:body])['loadbalancer']['id']
    end

    return loadbalancer_id
  end

  def update_loadbalancer(id,loadbalancer)
    fail ArgumentError, 'loadbalancer is nil' if loadbalancer.nil?

    options = {
    }
    response = @loadbalancer_request.update_lbaas_loadbalancer(id, options)
    if response[:'status'] == 204 || response[:'status'] == 200
      return true
    else
      return false
    end
  end

  def is_exist_loadbalancer(loadbalancer_name)
    fail ArgumentError, 'loadbalancer_name is nil' if loadbalancer_name.nil? || loadbalancer_name.empty?

    filters = {'name' => loadbalancer_name}
    response = @loadbalancer_request.list_lbaas_loadbalancers(filters)
    loadbalancers = JSON.parse(response[:body])['loadbalancers']

    if loadbalancers.count > 0
      return true
    else
      return false
    end
  end

  def get_loadbalancer_id(loadbalancer_name)
    fail ArgumentError, 'loadbalancer_name is nil' if loadbalancer_name.nil? || loadbalancer_name.empty?

    filters = {'name' => loadbalancer_name}
    response = @loadbalancer_request.list_lbaas_loadbalancers(filters)
    loadbalancers = JSON.parse(response[:body])['loadbalancers']

    if loadbalancers.count > 0
      return loadbalancers[0]['id']
    else
      return false
    end
  end

  def get_loadbalancer(loadbalancer_id)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    response = @loadbalancer_request.get_lbaas_loadbalancer(loadbalancer_id)

    loadbalancer_dto = JSON.parse(response[:body])['loadbalancer']
    if !loadbalancer_dto.nil?
      loadbalancer = LoadbalancerModel.new(loadbalancer_dto['vip_subnet_id'], loadbalancer_dto['provider'],
                                           loadbalancer_dto['tenant_id'], loadbalancer_dto['vip_address'],
                                           loadbalancer_dto['id'], loadbalancer_dto['provisioning_status'],
                                           loadbalancer_dto['operating_status'])
      loadbalancer.label.name=(loadbalancer_dto['name'])
      loadbalancer.label.description=(loadbalancer_dto['description'])
      loadbalancer.admin_state_up=(loadbalancer_dto['admin_state_up'])
      loadbalancer.listeners=(loadbalancer_dto['listeners'])
    end

    return loadbalancer
  end

  def delete_loadbalancer(loadbalancer_id)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?

    response = @loadbalancer_request.wait(loadbalancer_id).delete_lbaas_loadbalancer(loadbalancer_id)
    return response[:'status'] == 204 || response[:'status'] == 404 ? true : false
  end

  ############################################################################################

  def get_service_providers
    response = @loadbalancer_request.get_service_provider
    service_providers_dto = JSON.parse(response[:body])['service_providers']

    return service_providers_dto
  end

  def status
    service_providers = get_service_providers
    if !service_providers.nil?
      status = true
    else
      status = false
    end
    return status
  end

end
