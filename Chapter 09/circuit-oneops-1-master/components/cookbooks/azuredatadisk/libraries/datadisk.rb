require File.expand_path('../../../azure_base/libraries/azure_base_manager.rb', __FILE__)
require 'azure_mgmt_compute'
require 'azure_mgmt_storage'
require 'azure'

class Datadisk < AzureBase::ResourceGroupManager
  
  attr_accessor :device_maps,
                :rg_name_persistent_storage,
                :storage_account_name,
                :storage_account_access_key1,
                :instance_name,
                :compute_client,
                :storage_client
             
                
      def initialize(node)
      super(node)
          
          OOLog.info("App Name is: #{node[:app_name]}")
          case node[:app_name]
            when /storage/
             
            if node['device_map'] != nil 
              @device_maps = node['device_map'].split(" ")
              @device_maps.each do |dev|
                @rg_name_persistent_storage = dev.split(":")[0]
                @storage_account_name = dev.split(":")[1]
                break
              end
            elsif !node.workorder.rfcCi.ciAttributes["device_map"].empty?
              @device_maps = node.workorder.rfcCi.ciAttributes["device_map"].split(" ")
              @device_maps.each do |dev|
                @rg_name_persistent_storage = dev.split(":")[0]
                @storage_account_name = dev.split(":")[1]
                break
              end
            end 
            
             node.workorder.payLoad[:DependsOn].each do |dep|
              if dep["ciClassName"] =~ /Compute/ 
                 @instance_name = dep[:ciAttributes][:instance_name]
                end
              end       
            when /volume/
              
              node.workorder.payLoad[:DependsOn].each do |dep|
              if dep["ciClassName"] =~ /Storage/
                storage = dep
                 OOLog.info("storage dependson found")
                 OOLog.info("storage not NIL")
                attr = storage[:ciAttributes]
                OOLog.info("attr"+attr.inspect())
                @device_maps = attr['device_map'].split(" ")
                @device_maps.each do |dev|
                  @rg_name_persistent_storage = dev.split(":")[0]
                  @storage_account_name = dev.split(":")[1]
                  break
                end
                break
               end  
              end
            
              if node.workorder.payLoad.has_key?("ManagedVia")
                @instance_name = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_name"]
              end
            when /compute/
              @rg_name_persistent_storage = node['platform-resource-group']
              @storage_account_name = node['storage_account']                          
          end
          @compute_client = Azure::ARM::Compute::ComputeManagementClient.new(@creds)
          @compute_client.subscription_id = @subscription
          @storage_client = Azure::ARM::Storage::StorageManagementClient.new(@creds)
          @storage_client.subscription_id = @subscription         
          @storage_account_access_key1= get_storage_access_key()                             
      end

    def create()
      begin
      i = 1
      @device_maps.each do |dev_vol|
        slice_size = dev_vol.split(":")[3]
        dev_id = dev_vol.split(":")[4]
        storage_account_name = dev_vol.split(":")[1]
        component_name = dev_vol.split(":")[2]
        storage_account_rg_name = dev_vol.split(":")[0]
        dev_name = dev_id.split("/").last
        OOLog.info("slice_size :#{slice_size}, dev_id: #{dev_id}")
        vhd_blobname = "https://#{@storage_account_name}.blob.core.windows.net/vhds/#{@storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
        if check_blob_exist(vhd_blobname) == true
          OOLog.fatal("disk name exists already")
        else
          c=Azure::Core.config()
          c.storage_access_key = @storage_account_access_key1
          c.storage_account_name = @storage_account_name
          service = Azure::Blob::BlobService.new()
          container = "vhds"
          service.create_page_blob(container,vhd_blobname,slice_size)
        end
      end
      rescue Azure::Core::Http::HTTPError => e
        OOLog.info("error type:#{e.type}")        
        OOLog.debug("Failed to create the disk: #{e.description}")
      rescue Exception => e
        OOLog.debug("Failed to create the disk: #{e.inspect}")
      end     
    end

    def attach()
      vols = Array.new
      dev_list = ""
      i = 1
      dev_id=""
      OOLog.info('Subscription id is: ' + @subscription)
      @device_maps.each do |dev_vol|
        slice_size = dev_vol.split(":")[3]
        dev_id = dev_vol.split(":")[4]
        storage_account_name = dev_vol.split(":")[1]
        component_name = dev_vol.split(":")[2]
        storage_account_rg_name = dev_vol.split(":")[0]
        OOLog.info("slice_size :#{slice_size}, dev_id: #{dev_id}")
        vm = get_vm_info()

        #Add a data disk
         flag = false
         (vm.properties.storage_profile.data_disks).each do |disk|
           if disk.lun == i-1
             flag = true
           end
         end
         if flag == true
           i = i+1
           next
        end
        vm.properties.storage_profile.data_disks.push(build_storage_profile(i,component_name,slice_size,dev_id))
        attach_disk_to_vm(vm)
        OOLog.info("Adding #{dev_id} to the dev list")
        i = i+1
      end
      dev_id
    end

    #attach disk to the VM

    def attach_disk_to_vm(vm)
      begin
        start_time = Time.now.to_i
        OOLog.info("Attaching Storage disk ....")
        vm_promise = @compute_client.virtual_machines.create_or_update(@rg_name, @instance_name, vm)
        my_vm = vm_promise.value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("Storage Disk attached #{duration} seconds")
        OOLog.info("VM: #{my_vm.body.name} UPDATED!!!")
        return true
      rescue  MsRestAzure::AzureOperationError =>e
    OOLog.debug( e.body.inspect)
          if e.body.to_s =~ /InvalidParameter/ && e.body.to_s =~ /already exists/
            OOLog.debug("The disk is already attached")
          else
            OOLog.fatal(e.body)
          end
      rescue MsRestAzure::CloudErrorData =>e
      OOLog.fatal(e.body.message)
      rescue Exception => ex
          OOLog.fatal(ex.message)
      end
    end

    # Get the information about the VM
    def get_vm_info()
      promise = @compute_client.virtual_machines.get(@rg_name, @instance_name)
      result = promise.value!
      OOLog.info("vm info :"+result.body.inspect)
      return result.body
    end

    #Get storage account name to use

    def get_storage_account_name(vm)
      storage_account_name=((vm.properties.storage_profile.os_disk.vhd.uri).split(".")[0]).split("//")[1]
      OOLog.info("storage account to use:"+storage_account_name)
      storage_account_name
    end

    # build the storage profile object to add a new datadisk
    def build_storage_profile(disk_no,component_name,slice_size,dev_id)
      data_disk2 = Azure::ARM::Compute::Models::DataDisk.new
      dev_name = dev_id.split("/").last
      data_disk2.name = "#{component_name}-datadisk-#{dev_name}"
      OOLog.info("data_disk:"+data_disk2.name)
      data_disk2.lun = disk_no-1
      OOLog.info("data_disk lun:"+data_disk2.lun.to_s)
      data_disk2.disk_size_gb = slice_size
      data_disk2.vhd = Azure::ARM::Compute::Models::VirtualHardDisk.new
      data_disk2.vhd.uri = "https://#{@storage_account_name}.blob.core.windows.net/vhds/#{@storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
      OOLog.info("data_disk uri:"+data_disk2.vhd.uri)
      data_disk2.caching = Azure::ARM::Compute::Models::CachingTypes::ReadWrite
      blob_name = "#{@storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
      is_new_disk_or_old = check_blob_exist(blob_name)
      if is_new_disk_or_old == true
        data_disk2.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::Attach
      else
        data_disk2.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::Empty
      end
      data_disk2
    end

    def check_blob_exist(blobname)
      c=Azure::Core.config()
      c.storage_access_key = @storage_account_access_key1
      c.storage_account_name = @storage_account_name
  
      service = Azure::Blob::BlobService.new()
      container = "vhds"
      begin
        blob_prop = service.get_blob_properties(container,blobname)
        Chef::Log.info("Blob properties #{blob_prop.inspect}")
        if blob_prop != nil
          OOLog.info("disk exists")
          return true
        end
      rescue Exception => e
        OOLog.debug(e.message)
        OOLog.debug(e.message.inspect)
        return false
      end
    end

    def get_storage_access_key()
      OOLog.info("Getting storage account keys ....")
      storage_account_keys= @storage_client.storage_accounts.list_keys(@rg_name_persistent_storage,@storage_account_name).value!
      OOLog.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
      key1 = storage_account_keys.body.key1
      key2 = storage_account_keys.body.key2
      return key2
    end
    
    def delete_datadisk()
      @device_maps.each do |dev|
        dev_id = dev.split(":")[4]
        storage_account_name = dev.split(":")[1]
        component_name = dev.split(":")[2]
        dev_name = dev_id.split("/").last
        blobname = "#{storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
        status = delete_disk_by_name(blobname)
        if status == "DiskUnderLease"
          detach()
          delete_disk_by_name(blobname)
        end
      end
    end
    
    def delete_disk_by_name(blobname)
      c=Azure::Core.config()
      c.storage_access_key = @storage_account_access_key1
      c.storage_account_name = @storage_account_name
      service = Azure::Blob::BlobService.new()

      container = "vhds"
      # Delete a Blob
      begin
        delete_result = "success"
        retry_count = 20
        begin
          if retry_count > 0
            OOLog.info("Trying to delete the disk page (page blob):#{blobname} ....")
            delete_result = service.delete_blob(container, blobname)
          end
          retry_count = retry_count-1
        end until delete_result == nil
        if delete_result !=nil && retry_count == 0
          OOLog.debug("Error in deleting the disk (page blob):#{blobname}")
        end
      rescue Azure::Core::Http::HTTPError => e
        OOLog.info("error type:#{e.type}")
        if e.type == "LeaseIdMissing"
          OOLog.debug("Failed to delete the disk because there is currently a lease on the blob. Make sure to delete all volumes on the disk attached before detaching disk from VM")
          return "DiskUnderLease"
        end
        OOLog.debug("Failed to delete the disk: #{e.description}")
      rescue Exception => e
        OOLog.debug("Failed to delete the disk: #{e.inspect}")
        return e
      end
      OOLog.info("Successfully deleted the disk(page blob):#{blobname}")
      return "success"
    end

    def detach()
   
      i=1
      vm = nil
      vm = get_vm_info()
      @device_maps.each do |dev_vol|
        slice_size = dev_vol.split(":")[3]
        dev_id = dev_vol.split(":")[4]
        storage_account_name = dev_vol.split(":")[1]
        component_name = dev_vol.split(":")[2]
        storage_account_rg_name = dev_vol.split(":")[0]
        dev_name = dev_id.split("/").last
        diskname = "#{component_name}-datadisk-#{dev_name}"
        #Detach a data disk
        flag = false
        (vm.properties.storage_profile.data_disks).each do |disk|
          if disk.name == diskname
            OOLog.info("deleting disk at lun:"+(disk.lun).to_s + " dev:#{dev_name} ")
            vm.properties.storage_profile.data_disks.delete_at(i-1)
          end
         end
         end
         if vm != nil
           OOLog.info("updating VM with these properties" + vm.inspect())
           update_vm_properties(vm)
         end
      end
    
        #detach disk from the VM

    def update_vm_properties(vm)
      begin
        start_time = Time.now.to_i
        vm_promise = @compute_client.virtual_machines.create_or_update(@rg_name, @instance_name, vm)
        my_vm = vm_promise.value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("Storage Disk detached #{duration} seconds")
        OOLog.info("VM: #{my_vm.body.name} UPDATED!!!")
        return true
      rescue  MsRestAzure::AzureOperationError =>e
          OOLog.fatal(e.body)
      rescue Exception => ex
          OOLog.fatal(ex.message)
      end
    end
    
    
    
  end

