
class VirtualMachineModel
  def initialize(name)
    fail ArgumentError, 'name is invalid' if name.nil? || name.empty?

    @name = name
  end

  attr_reader :name, :cpus, :memory_mb, :guest_id, :template_path, :datacenter, :cluster, :datastore, :resource_pool,
              :power_on, :connection_state, :volumes, :interfaces, :cdroms, :customization_spec

  def cpus=(cpus)
      cpus = Integer(cpus)
      @cpus = cpus
  end

  def memory_mb=(memory_mb)
      memory_mb = Integer(memory_mb)
      @memory_mb = memory_mb
  end

  def guest_id=(guest_id)
    @guest_id = guest_id
  end

  def template_path=(template_path)
    @template_path = template_path
  end

  def datacenter=(datacenter)
    @datacenter = datacenter
  end

  def cluster=(cluster)
    @cluster = cluster
  end

  def datastore=(datastore)
    @datastore = datastore
  end

  def resource_pool=(resource_pool)
    @resource_pool = resource_pool
  end

  def power_on=(power_on)
    @power_on = power_on
  end

  def connection_state=(connection_state)
    @connection_state = connection_state
  end

  def volumes=(volumes)
    if volumes.is_a?(Array)
      @volumes = volumes
    else
      fail ArgumentError, 'volumes is invalid'
    end
  end

  def interfaces=(interfaces)
    if interfaces.is_a?(Array)
      @interfaces = interfaces
    else
      fail ArgumentError, 'interfaces is invalid'
    end
  end

  def customization_spec=(customization_spec)
    @customization_spec = customization_spec
  end

  def serialize_object
    object = {}
    object['name'] = @name
    object['numCPUs'] = @cpus
    object['memoryMB'] = @memory_mb
    object['guest_id'] = @guest_id
    object['template_path'] = @template_path
    object['datacenter'] = @datacenter
    object['cluster'] = @cluster
    object['datastore'] = @datastore
    object['resource_pool'] = @resource_pool
    object['power_on'] = @power_on
    object['connection_state'] = @connection_state
    object['volumes'] = @volumes
    object['interfaces'] = @interfaces
    if !@customization_spec.nil? then object['customization_spec'] = @customization_spec end

    return object
  end
end
