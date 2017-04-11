# module to contain classes for dealing with the Azure Network features.
module AzureNetwork

  # Class that defines the functions for manipulating virtual networks in Azure
  class VirtualNetwork

    attr_accessor :location,
                  :name,
                  :address,
                  :sub_address,
                  :dns_list

    attr_reader :creds, :subscription

    def initialize(creds, subscription)
      @creds = creds
      @subscription = subscription
      @client =
        Azure::ARM::Network::NetworkResourceProviderClient.new(creds)
      @client.subscription_id = subscription
    end

    # this method creates the vnet object that is later passed in to create
    # the vnet
    def build_network_object
      OOLog.info("network_address: #{@address}")
      address_space = Azure::ARM::Network::Models::AddressSpace.new
      address_space.address_prefixes = [@address]

      ns_list = Array.new
      for i in 0..@dns_list.length-1
        OOLog.info('dns address[' + i.to_s + ']: ' + @dns_list[i].strip)
        ns_list.push(@dns_list[i].strip)
      end
      dhcp_options = Azure::ARM::Network::Models::DhcpOptions.new
      if ns_list != nil
        dhcp_options.dns_servers = ns_list
      end

      subnet = AzureNetwork::Subnet.new(@creds, @subscription)
      subnet.sub_address = @sub_address
      subnet.name = @name
      sub_nets = subnet.build_subnet_object

      virtual_network_properties =
        Azure::ARM::Network::Models::VirtualNetworkPropertiesFormat.new
      virtual_network_properties.address_space = address_space
      virtual_network_properties.dhcp_options = dhcp_options
      virtual_network_properties.subnets = sub_nets

      virtual_network = Azure::ARM::Network::Models::VirtualNetwork.new
      virtual_network.location = @location
      virtual_network.properties = virtual_network_properties

      virtual_network
    end

    # this will create/update the vnet
    def create_update(resource_group_name, virtual_network)
      begin
        OOLog.info("Creating Virtual Network '#{@name}' ...")
        start_time = Time.now.to_i
        promise = @client.virtual_networks.create_or_update(resource_group_name, @name, virtual_network)
        response = promise.value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info('Successfully created/updated network name: ' + @name)
        OOLog.info("operation took #{duration} seconds")
        response
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Failed creating/updating vnet: #{@name} with exception #{e.body}")
      rescue => ex
        OOLog.fatal("Failed creating/updating vnet: #{@name} with exception #{ex.message}")
      end
    end

    # this method will return a vnet from the name given in the resource group
    def get(resource_group_name)
      OOLog.fatal('VNET name is nil. It is required.') if @name.nil?

      begin
        OOLog.info("Getting Virtual Network '#{@name}' ...")
        start_time = Time.now.to_i

        promise = @client.virtual_networks.get(resource_group_name, @name)
        response = promise.value!

        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")

        response
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{ex.message}")
      end
    end

    # this method will return a list of vnets from the resource group
    def list(resource_group_name)
      begin
        OOLog.info("Getting vnets from Resource Group '#{resource_group_name}' ...")
        start_time = Time.now.to_i
        promise = @client.virtual_networks.list(resource_group_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting all vnets for resource group. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting all vnets for resource group. Exception: #{ex.message}")
      end
    end

    # this method will return a list of vnets from the subscription
    def list_all
      begin
        OOLog.info("Getting subscription vnets ...")
        start_time = Time.now.to_i
        promise = @client.virtual_networks.list_all()
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting all vnets for the sub. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting all vnets for the sub. Exception: #{ex.message}")
      end
    end

    # this method will return a vnet from the name given in the resource group
    def exists?(resource_group_name)
      OOLog.fatal('VNET name is nil. It is required.') if @name.nil?

      begin
        OOLog.info("Checking if Virtual Network '#{@name}' Exists! ...")
        promise = @client.virtual_networks.get(resource_group_name, @name)
        response = promise.value!
        OOLog.info('VNET EXISTS!!')
        return true
      rescue MsRestAzure::AzureOperationError => e
        OOLog.info("Exception from Azure: #{e.body}")
        # check the error
        # If the error is that it doesn't exist, return true
        OOLog.info("Error of Exception is: '#{e.body.values[0]}'")
        OOLog.info("Code of Exception is: '#{e.body.values[0]['code']}'")
        if(e.body.values[0]['code'] == 'ResourceNotFound')
          OOLog.info('VNET DOES NOT EXIST!!')
          return false
        else
          # for all other errors, throw the exception back
          OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{e.body}")
        end
      rescue => ex
        OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{ex.message}")
      end
    end

  end  # end of class

end
