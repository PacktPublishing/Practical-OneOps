require 'azure_mgmt_compute'
require 'azure_mgmt_storage'

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

total_start_time = Time.now.to_i

#set the proxy if it exists as a cloud var
Utils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

######################################
# get everything needed from the node
# and info that you will need for all the recipes
######################################
cloud_name = node[:workorder][:cloud][:ciName]
OOLog.info("Cloud Name: #{cloud_name}")
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
# ostype = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:ostype]

# OOLog.info("OSTYPENEWDEC22: #{ostype}")
# OOLog.info("os type cloud : #{cloud}")


location = compute_service[:location]
express_route_enabled = compute_service[:express_route_enabled]
OOLog.info('Express Route is enabled: ' + express_route_enabled )
subscription = compute_service[:subscription]
OOLog.info("Subscription ID: #{subscription}")
ci_id = node[:workorder][:rfcCi][:ciId]
OOLog.info("ci_id: #{ci_id.to_s}")

# this is the resource group the preconfigured vnet will be in
master_resource_group_name = compute_service[:resource_group]
# preconfigured vnet name
preconfigured_network_name = compute_service[:network]

#TODO:validate data entry with regex.
# we get these values if it's NOT express route.
network_address = compute_service[:network_address].strip
subnet_address_list = (compute_service[:subnet_address]).split(',')
dns_list = (compute_service[:dns_ip]).split(',')

initial_user = compute_service[:initial_user]
# put initial_user on the node for the following recipes
node.set[:initial_user] = initial_user
keypair = node[:workorder][:payLoad][:SecuredBy].first
pub_key = keypair[:ciAttributes][:public]
server_name = node[:server_name]
#######################################

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

resource_group_name = node['platform-resource-group']
OOLog.info('Resource group name: ' + resource_group_name)

if express_route_enabled == 'true'
  ip_type = 'private'
else
  ip_type = 'public'
end

OOLog.info('ip_type: ' + ip_type)

# get the credentials needed to call Azure SDK
creds =
  Utils.get_credentials(compute_service[:tenant_id],
                        compute_service[:client_id],
                        compute_service[:client_secret]
                       )

# must do this until all is refactored to use the util above.
node.set['azureCredentials'] = creds

# create the VM in the platform specific resource group and availability set
client = ComputeManagementClient.new(creds)
client.subscription_id = subscription

node.set['VM_exists'] = false
#check whether the VM with given name exists already

OOLog.info ('LOGO TEST')
begin
  promise = client.virtual_machines.get(resource_group_name, server_name)
  result = promise.value!
  node.set['VM_exists'] = true
  OOLog.info ('LOGO TEST BEGIN')
rescue MsRestAzure::AzureOperationError => e
  OOLog.debug("Error Body: #{e.body}")
  OOLog.debug("VM doesn't exist. Leaving the VM_exists flag false")
end

# invoke recipe to build the OS profile
begin
  osprofilecls = AzureCompute::OsProfile.new
  if compute_service[:ostype].include?("windows")
    osprofile = osprofilecls.windows_build_profile(initial_user, pub_key, server_name)
  else  
     osprofile = osprofilecls.build_profile(initial_user, pub_key, server_name)
  end
  rescue => ex
  OOLog.fatal("Error getting os profile: #{ex.message}")
end

# get the hard ware profile class
begin
  OOLog.info("VM Size: #{node[:size_id]}")
  hwprofilecls = AzureCompute::HardwareProfile.new
  hwprofile = hwprofilecls.build_profile(node[:size_id])
rescue => ex
  OOLog.fatal("Error getting hardware profile: #{ex.message}")
end

# get the storage profile
begin
  storageprofilecls = AzureCompute::StorageProfile.new(creds,subscription)
  storageprofilecls.location = location
  storageprofilecls.resource_group_name = resource_group_name
  storageprofile =
    storageprofilecls.build_profile(node)
rescue => ex
  OOLog.fatal("Error getting storage profile: #{ex.message}")
end

# get the network securtiy group name
secgroup_name = node.workorder.payLoad.DependsOn[0]['ciName']

# invoke class to build the network profile
begin
  network_interface_cls =
    AzureNetwork::NetworkInterfaceCard.new(creds, subscription)
  network_interface_cls.location = location
  network_interface_cls.rg_name = resource_group_name
  network_interface_cls.ci_id = ci_id

  network_profile =
    network_interface_cls.build_network_profile(express_route_enabled,
                                                master_resource_group_name,
                                                preconfigured_network_name,
                                                network_address,
                                                subnet_address_list,
                                                dns_list,
                                                ip_type,
                                                secgroup_name)
rescue => ex
  OOLog.fatal("Error getting network profile: #{ex.message}")
end

# set the ip on the node as the private ip
node.set['ip'] = network_interface_cls.private_ip
# write the ip information to stdout for the inductor to pick up and use.
if ip_type == 'private'
  puts "***RESULT:private_ip="+node['ip']
  puts "***RESULT:public_ip="+node['ip']
  puts "***RESULT:dns_record="+node['ip']
else
  puts "***RESULT:private_ip="+node['ip']
end

# get the availability set to use
availability_set = AzureCompute::AvailabilitySet.new(compute_service)

# Create a model for new virtual machine
props = VirtualMachineProperties.new
props.os_profile = osprofile
props.hardware_profile = hwprofile
props.storage_profile = storageprofile
props.network_profile = network_profile
props.availability_set = availability_set.get(resource_group_name, node['platform-availability-set'])

params = VirtualMachine.new
params.type = 'Microsoft.Compute/virtualMachines'
params.properties = props
params.location = location
begin
  start_time = Time.now.to_i
  OOLog.info("Creating New Azure VM :" + server_name)
  # create the VM in the platform resource group
  vm_promise = client.virtual_machines.create_or_update(resource_group_name, server_name, params)
  my_new_vm = vm_promise.value!
  end_time = Time.now.to_i
  duration = end_time - start_time
  OOLog.info("Azure VM created in #{duration} seconds")
	OOLog.info("New VM: #{my_new_vm.body.name} CREATED!!!")
  puts "***RESULT:instance_id="+my_new_vm.body.id
rescue MsRestAzure::AzureOperationError => e
  OOLog.fatal("Error Creating VM: #{e.body}")
rescue MsRestAzure::CloudErrorData => ce
  OOLog.fatal("Error Creating VM: #{ce.body.message}")
rescue => ex
  OOLog.fatal("Error Creating VM: #{ex.message}")
end

# for public deployments we need to get the public ip address after the vm
# is created
if ip_type == 'public'
  # need to get the public ip that was assigned to the VM
  begin
    # get the pip name
    public_ip_name = Utils.get_component_name("publicip",ci_id)
    OOLog.info("public ip name: #{public_ip_name }")

    pip = AzureNetwork::PublicIp.new(creds,subscription)
    publicip_details = pip.get(resource_group_name, public_ip_name)
    publicip = publicip_details.response.body
    obj=JSON.parse(publicip)
    pubip_address = obj['properties']['ipAddress']
    OOLog.info("public ip found: #{pubip_address}")
    # set the public ip and dns record on stdout for the inductor
    puts "***RESULT:public_ip=#{pubip_address}"
    puts "***RESULT:dns_record=#{pubip_address}"
    node.set['ip'] = pubip_address
  rescue MsRestAzure::AzureOperationError => e
    OOLog.fatal("Error getting pip from Azure: #{e.body}")
  rescue => ex
    OOLog.fatal("Error getting pip from Azure: #{ex.message}")
  end
end
if !compute_service[:ostype].include?("windows")
  include_recipe "compute::ssh_port_wait"
end  

rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
customer_domain = node["customer_domain"]
owner = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || "na"
node.set["max_retry_count_add"] = 30

mgmt_url = "https://"+node.mgmt_domain
if node.has_key?("mgmt_url") && !node.mgmt_url.empty?
  mgmt_url = node.mgmt_url
end

metadata = {
  "owner" => owner,
  "mgmt_url" =>  mgmt_url,
  "organization" => node.workorder.payLoad[:Organization][0][:ciName],
  "assembly" => node.workorder.payLoad[:Assembly][0][:ciName],
  "environment" => node.workorder.payLoad[:Environment][0][:ciName],
  "platform" => node.workorder.box.ciName,
  "component" => node.workorder.payLoad[:RealizedAs][0][:ciId].to_s,
  "instance" => node.workorder.rfcCi.ciId.to_s
}

puts "***RESULT:metadata="+JSON.dump(metadata)
total_end_time = Time.now.to_i
duration = total_end_time - total_start_time
OOLog.info("Total Time for azure::add_node recipe is #{duration} seconds")
