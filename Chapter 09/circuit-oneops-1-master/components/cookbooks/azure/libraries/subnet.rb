# module to contain classes for dealing with the Azure Network features.
require 'azure_mgmt_network'
module AzureNetwork

  # thie class has all the methods in it to handle Azure's subnet.
  class Subnet

    attr_accessor :sub_address, :name

    attr_reader :creds, :subscription

    # Include SDK modules to ease access to network classes.
    include Azure::ARM::Network
    include Azure::ARM::Network::Models

    def initialize(creds, subscription_id)
      @creds = creds
      @subscription = subscription_id
      @client =
        Azure::ARM::Network::NetworkResourceProviderClient.new(creds)
      @client.subscription_id = subscription_id
    end

    # this builds an array of subnets to be used for creating a vnet.
    def build_subnet_object
      sub_nets = Array.new
      for i in 0..@sub_address.length-1
        OOLog.info('sub_address[' + i.to_s + ']: ' + @sub_address[i].strip)
        subnet_properties =
          Azure::ARM::Network::Models::SubnetPropertiesFormat.new
        subnet_properties.address_prefix = @sub_address[i].strip

        subnet = Azure::ARM::Network::Models::Subnet.new
        subnet.name = 'subnet_' + i.to_s + '_' + @name
        subnet.properties = subnet_properties
        sub_nets.push(subnet)
        OOLog.info('Subnet name is: ' + subnet.name)
      end
      sub_nets
    end

    # this method will return the first subnet of the array that has available
    # ips
    def get_subnet_with_available_ips(subnets, express_route_enabled)
      subnets.each do |subnet|
        next if subnet.name.downcase == "gatewaysubnet"

        OOLog.info('checking for ip availability in ' + subnet.name)
        address_prefix = subnet.properties.address_prefix

        if express_route_enabled == 'true'
          #Broadcast(1)+Gateway(1)+azure express routes(3) = 5
          total_num_of_ips_possible =
            (2 ** (32 - (address_prefix.split('/').last.to_i)))-5
        else
          #Broadcast(1)+Gateway(1)
          total_num_of_ips_possible =
            (2 ** (32 - (address_prefix.split('/').last.to_i)))-2
        end
        OOLog.info("Total number of ips possible is: #{total_num_of_ips_possible.to_s}")

        if subnet.properties.ip_configurations.nil?
          no_ips_inuse = 0
        else
          no_ips_inuse = subnet.properties.ip_configurations.length
        end
        OOLog.info("Num of ips in use: #{no_ips_inuse.to_s}")

        remaining_ips = total_num_of_ips_possible - (no_ips_inuse)
        if remaining_ips == 0
          OOLog.info("No IP address remaining in the Subnet '#{subnet.name}'")
          OOLog.info("Total number of subnets(subnet_name_list.count) = #{(subnets.count).to_s}")
          OOLog.info('checking the next subnet')
          next #check the next subnet
        else
          return subnet
        end
      end
      OOLog.fatal('No IP addresses available in any allocated subnets.')
    end

    # this method will return all subnets in the RG and vnet.
    def list(resource_group_name, vnet_name)
      begin
        OOLog.info("Getting all subnets from Resource Group '#{resource_group_name}'/vnet '#{vnet_name}'  ...")
        start_time = Time.now.to_i
        promise = @client.subnets.list(resource_group_name, vnet_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog("operation took #{duration} seconds")
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting all subnets for vnet. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting all subnets for vnet. Exception: #{ex.message}")
      end
    end

    # retrieve the subnet
    def get(resource_group_name, vnet_name, subnet_name)
      begin
        OOLog.info("Getting subnet '#{subnet_name}' from Resource Group '#{resource_group_name}'/vnet '#{vnet_name}'  ...")
        start_time = Time.now.to_i
        promise =
          @client.subnets.get(resource_group_name, vnet_name, subnet_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting subnet.  Excpetion: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting subnet.  Excpetion: #{ex.message}")
      end
    end

  end

end
