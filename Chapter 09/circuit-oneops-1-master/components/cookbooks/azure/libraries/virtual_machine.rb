module AzureCompute
  class VirtualMachine

    attr_reader :client, :subscription_id

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      @client.subscription_id = subscription_id
      @subscription_id = subscription_id
    end

    def get_subscription_vms
      begin
        OOLog.info("Fetching virtual machines from subscription")
        start_time = Time.now.to_i
        promise = @client.virtual_machines.list_all()
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        return result
      rescue MsRest::DeserializationError => de
        OOLog.info("Error getting subscription VMs")
        OOLog.info("Error: #{de.message}")
        OOLog.info("Error Message: #{de.exception_message}")
        OOLog.info("Error Body: #{de.response_body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      rescue  MsRestAzure::AzureOperationError => e
        OOLog.info("Error getting subscription VMs")
        OOLog.info("Error Response: #{e.response}")
        OOLog.info("Error Body: #{e.body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      rescue Exception => ex
        OOLog.info("Error getting subscription VMs")
        OOLog.info("Error Response: #{ex.response}")
        OOLog.info("Error Body: #{ex.body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      end
    end

    def get_resource_group_vms(resource_group_name)
      begin
        OOLog.info("Fetcing virtual machines in '#{resource_group_name}'")
        start_time = Time.now.to_i
        promise = @client.virtual_machines.list(resource_group_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        OOLog.info("Error getting resource group VM")
        OOLog.info("Error Response: #{e.response}")
        OOLog.info("Error Body: #{e.body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      end
    end

    def get(resource_group_name, vm_name)
      begin
        OOLog.info("Fetching VM '#{vm_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.virtual_machines.get(resource_group_name, vm_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        OOLog.fatal("Error fetching VM.  #{e.body}")
      rescue => ex
        OOLog.fatal("Error fetching VM: #{ex.message}")
      end
    end

    def start(resource_group_name, vm_name)
      begin
        OOLog.info("Starting VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        @client.virtual_machines.start(resource_group_name, vm_name)
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("VM started in #{duration} seconds")
      rescue  MsRestAzure::AzureOperationError =>e
        OOLog.fatal("Error starting VM. #{e.response}")
      rescue Exception => ex
        OOLog.fatal("Error starting VM. #{ex.message}")
      end
    end

    def restart(resource_group_name, vm_name)
      begin
        OOLog.info("Restarting VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        response = @client.virtual_machines.restart(resource_group_name, vm_name).value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        response
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error restarting VM.  #{e.body}")
      rescue => ex
        OOLog.fatal("Error restarting VM: #{ex.message}")
      end
    end

    def power_off(resource_group_name, vm_name)
      begin
        OOLog.info("Power off VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        @client.virtual_machines.power_off(resource_group_name, vm_name).value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
      rescue  MsRestAzure::AzureOperationError =>e
        OOLog.fatal("Error powering off VM. #{e.response}")
      rescue Exception => ex
        OOLog.fatal("Error powering off VM. #{ex.message}")
      end
    end

  end

end