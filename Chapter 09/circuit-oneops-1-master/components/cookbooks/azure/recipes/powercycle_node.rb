require 'json'
require 'azure_mgmt_compute'

#set the proxy if it exists as a system prop
Utils.set_proxy_from_env(node)

cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]
credentials = Utils.get_credentials(compute_service[:tenant_id],
                                    compute_service[:client_id],
                                    compute_service[:client_secret])

location = compute_service[:location]
subscription_id = compute_service[:subscription]

ci = node[:workorder][:ci]
vm_name = ci[:ciAttributes][:instance_name]
node.set['vm_name'] = vm_name
metadata = ci[:ciAttributes][:metadata]
metadata_obj= JSON.parse(metadata)
org = metadata_obj['organization']
assembly = metadata_obj['assembly']
environment = metadata_obj['environment']
platform_ciID = node.workorder.box.ciId

resource_group_name = AzureResources::ResourceGroup.get_name(org, assembly, platform_ciID, environment, location)
begin
  vm_svc = AzureCompute::VirtualMachine.new(credentials, subscription_id)
  vm_svc.power_off(resource_group_name, vm_name)
  vm_svc.start(resource_group_name, vm_name)
  OOLog.info("VM powercycle completed.")
  node.set['hard_reboot_result']= 'Success'
rescue Exception => e
  node.set['hard_reboot_result']= 'Error'
end
