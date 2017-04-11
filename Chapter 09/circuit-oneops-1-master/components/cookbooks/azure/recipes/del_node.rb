require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)

#set the proxy if it exists as a cloud var
Utils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

#Get the vm object from azure given a resource group and compute name
def get_vm(client, resource_group_name, vm_name)
  begin
      puts("Getting VM #{vm_name}")
      start_time = Time.now.to_i
      promise = client.virtual_machines.get(resource_group_name, vm_name)
      result = promise.value!
      end_time = Time.now.to_i

      duration = end_time - start_time

      puts("VM fetched in #{duration} seconds")

      return result.body
    rescue MsRestAzure::AzureOperationError => e
      puts 'Error fetching VM'
      puts("Error Body: #{e.body}")
      return nil
    rescue => ex
      OOLog.fatal("Error fetching vm: #{ex.message}")
    end
end

# delete the NIC from the platform specific resource group
def delete_nic(credentials, subscription_id, resource_group_name, nic_name)
  begin
    start_time = Time.now.to_i
    networkclient = NetworkResourceProviderClient.new(credentials)
    networkclient.subscription_id = subscription_id
    promise = networkclient.network_interfaces.delete(resource_group_name, nic_name)
    result = promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("Deleting NIC '#{nic_name}' in #{duration} seconds")
  rescue MsRestAzure::AzureOperationError => e
    OOLog.fatal("***FAULT:FATAL=Error deleting NIC, resource group: '#{resource_group_name}', NIC name: '#{nic_name}', Error: #{e.body.values[0]['message']}")
  rescue => ex
    OOLog.fatal("***FAULT:FATAL=Error deleting NIC, resource group: '#{resource_group_name}', NIC name: '#{nic_name}', Error: #{ex.message}")
  end
end

#Delete public ip assocaited with the VM
def delete_publicip(credentials,subscription_id,resource_group_name, public_ip_name)
  begin
    start_time = Time.now.to_i
    networkclient = NetworkResourceProviderClient.new(credentials)
    networkclient.subscription_id = subscription_id
    promise = networkclient.public_ip_addresses.delete(resource_group_name, public_ip_name)
    details = promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("Deleting public ip '#{public_ip_name}' in #{duration} seconds")
 end
end

cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info('cloud_name is: ' + cloud_name)
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']

# handle token and credentials
subscription_id = compute_service['subscription']
Chef::Log.info('Subscription id is: ' + subscription_id)

# invoke recipe to get credentials
include_recipe "azure::get_credentials"

credentials = node['azureCredentials']

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

server_name = node['server_name']
cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info("Cloud Name: #{cloud_name}")
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
express_route_enabled = compute_service['express_route_enabled']
if express_route_enabled == 'true'
  ip_type = 'private'
else
  ip_type = 'public'
end
# delete the VM
begin
  start_time = Time.now.to_i
  client = ComputeManagementClient.new(credentials)
  client.subscription_id = subscription_id
  vm = nil
  vm = get_vm(client, node['platform-resource-group'], server_name)

  if vm.nil?
    Chef::Log.info("VM '#{server_name}' was not found. Nothing to delete. ")
  else
    #retrive the vhd name from the VM properties and use it to delete the associated VHD in the later step.
    vhd_uri = vm.properties.storage_profile.os_disk.vhd.uri
    storage_account  = (vhd_uri.split(".").first).split("//").last
    node.set["storage_account"] = storage_account
    node.set["vhd_uri"]=vhd_uri
    Chef::Log.info(vm.properties.inspect)
    if vm.properties.storage_profile.data_disks.count > 0
      node.set["datadisk_uri"] = vm.properties.storage_profile.data_disks[0].vhd.uri
    end
    ci_name = node['workorder']['rfcCi']['ciId']
    Chef::Log.info("Deleting Azure VM: '#{server_name}'")
    #delete the VM from the platform resource group
    result = client.virtual_machines.delete(node['platform-resource-group'], server_name).value!
    Chef::Log.info("Delete VM response is: #{result.inspect}")
    # delete the NIC. A NIC is created with each VM, so we will delete the NIC when we delete the VM
    nic_name = Utils.get_component_name("nic",ci_name)
    delete_nic(credentials, subscription_id, node['platform-resource-group'], nic_name)
    # public IP must be deleted after the NIC.
    if ip_type == 'public'
      public_ip_name = Utils.get_component_name("publicip",ci_name)
      delete_publicip(credentials, subscription_id, node['platform-resource-group'],public_ip_name)
    end
    #delete the blobs
    #Delete both Page blob(vhd) and Block Blob from the storage account
    #Delete both osdisk and datadisk blob
    include_recipe "azure::del_blobs"
    
  end
rescue MsRestAzure::AzureOperationError => e
  OOLog.fatal("Error deleting VM, resource group: #{node['platform-resource-group']}, VM name: #{node['server_name']}. Exception is=#{e.body.values[0]['message']}")
rescue => ex
  OOLog.fatal("Error deleting VM, resource group: #{node['platform-resource-group']}, VM name: #{node['server_name']}. Exception is=#{ex.message}")
 ensure
   end_time = Time.now.to_i
   duration = end_time - start_time
   Chef::Log.info("Deleting VM took #{duration} seconds")
end

Chef::Log.info("Exiting azure delete compute")
