require 'json'
require 'azure_mgmt_compute'

#set the proxy if it exists as a system prop
Utils.set_proxy_from_env(node)

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
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
  vm = vm_svc.get(resource_group_name, vm_name)
  # OOLog.info("server info: " + vm.server_info.inspect.gsub(/\n|\<|\>|\{|\}/,""))
  OOLog.info("Status result. Instance Name: [#{vm.name}]")
  OOLog.info("Status result. Type: [#{vm.type}]")
  OOLog.info("Status result. Location: [#{vm.location}]")
  OOLog.info("Status result. Computer Name: [#{vm.properties.os_profile.computer_name}]")
  node.set['status_result'] = 'Success'
rescue Exception => e
  node.set['status_result'] = 'Error'
end
