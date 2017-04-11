require File.expand_path('../../libraries/virtual_machine_manager', __FILE__)
require File.expand_path('../../libraries/models/virtual_machine_model', __FILE__)
require File.expand_path('../../libraries/models/volume_model', __FILE__)
require File.expand_path('../../libraries/models/nic_model', __FILE__)
require File.expand_path('../../libraries/models/cdrom_model', __FILE__)
require File.expand_path('../../libraries/models/tenant_model', __FILE__)

def get_volume(compute_provider, datastore, name, disk_mode, thin_provisioned, disk_size)
  volume_model = VolumeModel.new(datastore)
  volume_model.name = name
  volume_model.disk_mode = disk_mode
  volume_model.thin_provisioned = thin_provisioned
  volume_model.size_gb = disk_size
  volume_attributes = volume_model.serialize_object

  return compute_provider.volumes.new(volume_attributes)
end

def get_network_interface(compute_provider, service_compute)
  nic_model = NicModel.new(service_compute[:network], service_compute[:network])
  nic_model.status = 'ok'
  nic_model.summary = 'VM Network'
  nic_attributes = nic_model.serialize_object

  return compute_provider.interfaces.new(nic_attributes)
end

def get_cdrom(compute_provider, service_compute, instance_uuid = nil)
  if !instance_uuid.nil? && !instance_uuid.empty?
    cdrom_model = CdromModel.new(service_compute[:datastore], service_compute[:iso],
                                 instance_uuid)
    return cdrom_model.serialize_object
  else
    cdrom_model = CdromModel.new(service_compute[:datastore], service_compute[:iso])
  end
  cdroms_attributes =  cdrom_model.serialize_object

  return compute_provider.cdroms.new(cdroms_attributes)
end

def get_virtual_machine_attributes(service_compute, cpu_size, memory_size, volumes, network_interface)
  virtual_machine_model = VirtualMachineModel.new(node[:server_name])
  virtual_machine_model.cpus = cpu_size
  virtual_machine_model.memory_mb = memory_size
  virtual_machine_model.guest_id = service_compute[:guest_id]
  virtual_machine_model.datacenter = service_compute[:datacenter]
  virtual_machine_model.template_path = node[:image_id]
  virtual_machine_model.cluster = service_compute[:cluster]
  virtual_machine_model.datastore = service_compute[:datastore]
  virtual_machine_model.resource_pool = [service_compute[:cluster], service_compute[:resource_pool]]
  virtual_machine_model.power_on = false
  virtual_machine_model.connection_state = 'connected'
  virtual_machine_model.volumes = volumes
  virtual_machine_model.interfaces = [network_interface]

  return virtual_machine_model.serialize_object
end
#--------------------------------------------------
rfcCi = node[:workorder][:rfcCi]
cloud_name = node[:workorder][:cloud][:ciName]
service_compute = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

size_map = JSON.parse(service_compute[:sizemap])
size_values = size_map[rfcCi[:ciAttributes][:size]].split('x')
cpu_size = size_values[0]
memory_size = size_values[1]
disk_size = size_values[2]

public_key = node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:public]
bandwidth_throttle_rate = service_compute[:bandwidth_throttle_rate]

Chef::Log.info("Connecting to vCenter " + service_compute[:endpoint].to_s)
Chef::Log.info("Data Center " + service_compute[:datacenter].to_s)
Chef::Log.info("Cluster " + service_compute[:cluster].to_s)
tenant_model = TenantModel.new(service_compute[:endpoint], service_compute[:username], service_compute[:password], service_compute[:vsphere_pubkey])
compute_provider = tenant_model.get_compute_provider

volumes = Array.new
Chef::Log.info("configuring disks")
volumes.push(get_volume(compute_provider, service_compute[:datastore], 'os', 'PERSISTENT', true, 9))
secondary_volume = get_volume(compute_provider, service_compute[:datastore], 'data_disk', 'INDEPENDENT_PERSISTENT', true, disk_size)

Chef::Log.info("configuring network interfaces")
network_interface = get_network_interface(compute_provider, service_compute)

Chef::Log.info("configuring virtual machine")
vm_attributes = get_virtual_machine_attributes(service_compute, cpu_size, memory_size, volumes, network_interface)

rfc_action = rfcCi[:rfcAction]
if rfc_action == 'update'
  Chef::Log.info("Updating VM ..... " + node[:server_name].to_s)
  virtual_machine_manager = VirtualMachineManager.new(compute_provider, public_key, node[:server_name])
else
  Chef::Log.info("Creating VM ..... " + node[:server_name].to_s)
  start_time = Time.now
  Chef::Log.info("start time " + start_time.to_s)
  is_debug = node.workorder.payLoad[:Environment][0][:ciAttributes][:debug]
  virtual_machine_manager = VirtualMachineManager.new(compute_provider, public_key)
  virtual_machine_manager.bandwidth_throttle_rate = bandwidth_throttle_rate
  virtual_machine_manager.clone(vm_attributes, is_debug, secondary_volume)
  Chef::Log.info("end time " + Time.now.to_s)
  total_time = Time.now - start_time
  Chef::Log.info("Total time to create " + total_time.to_s)
end

node.set[:ip] = virtual_machine_manager.ip_address
Chef::Log.info("Exiting vSphere add_node ")
