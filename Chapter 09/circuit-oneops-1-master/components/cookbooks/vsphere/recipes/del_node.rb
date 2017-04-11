require File.expand_path('../../libraries/virtual_machine_manager', __FILE__)
require File.expand_path('../../libraries/models/tenant_model', __FILE__)

cloud_name = node[:workorder][:cloud][:ciName]
service_compute = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

Chef::Log.info("Connecting to vCenter " + service_compute[:endpoint].to_s)
Chef::Log.info("Data Center " + service_compute[:datacenter].to_s)
Chef::Log.info("Cluster " + service_compute[:cluster].to_s)
tenant_model = TenantModel.new(service_compute[:endpoint], service_compute[:username], service_compute[:password], service_compute[:vsphere_pubkey])
compute_provider = tenant_model.get_compute_provider

Chef::Log.info("Searching for VM ..... " + node[:server_name].to_s)
start_time = Time.now
Chef::Log.info("start time " + start_time.to_s)
public_key = node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:public]
virtual_machine_manager = VirtualMachineManager.new(compute_provider, public_key, node[:server_name])
if virtual_machine_manager.delete
  Chef::Log.info("deleted instance")
end
Chef::Log.info("end time " + Time.now.to_s)
total_time = Time.now - start_time
Chef::Log.info("Total time" + total_time.to_s)

Chef::Log.info("Exiting vSphere del_node ")
