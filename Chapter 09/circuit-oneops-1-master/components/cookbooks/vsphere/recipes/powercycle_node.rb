require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../libraries/virtual_machine_manager', __FILE__)

cloud_name = node[:workorder][:cloud][:ciName]
service_compute = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

tenant_model = TenantModel.new(service_compute[:endpoint], service_compute[:username], service_compute[:password], service_compute[:vsphere_pubkey])
compute_provider = tenant_model.get_compute_provider
instance_id = node[:compute][:instance_id]

Chef::Log.info("Powercycling instance: " + node[:compute][:instance_name].to_s)
public_key = node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:public]
virtual_machine_manager = VirtualMachineManager.new(compute_provider, public_key, instance_id)
is_powercycled = virtual_machine_manager.powercycle

if is_powercycled == true
  node.set[:ip] = virtual_machine_manager.ip_address
  Chef::Log.info("Powercycling Successful.")
else
  Chef::Log.error("Failed to Powercycle.")
end
