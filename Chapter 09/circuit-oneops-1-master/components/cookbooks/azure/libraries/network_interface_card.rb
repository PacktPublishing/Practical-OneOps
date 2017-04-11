#TODO: add checks in each method for rg_name
require File.expand_path('../../../azuresecgroup/libraries/network_security_group.rb', __FILE__)
# module to contain classes for dealing with the Azure Network features.
module AzureNetwork

  # class to implement all functionality needed for an Azure NIC.
  class NetworkInterfaceCard

    attr_accessor :location, :rg_name, :private_ip, :profile, :ci_id

    attr_reader :creds, :subscription

    def initialize(credentials, subscription_id)
      @creds = credentials
      @subscription = subscription_id
      @client =
        Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    # define the NIC's IP Config
    def define_nic_ip_config(ip_type, subnet)
      nic_ip_config_props =
        Azure::ARM::Network::Models::NetworkInterfaceIpConfigurationPropertiesFormat.new
      nic_ip_config_props.private_ipallocation_method =
        Azure::ARM::Network::Models::IpAllocationMethod::Dynamic
      nic_ip_config_props.subnet = subnet

      if ip_type == 'public'
        publicip = AzureNetwork::PublicIp.new(@creds, @subscription)
        publicip.location = @location
        # get public ip object
        public_ip_address = publicip.build_public_ip_object(@ci_id)
        # create public ip
        public_ip_if =
          publicip.create_update(@rg_name,
                                 public_ip_address.name,
                                 public_ip_address)

        # set the public ip on the nic ip config
        nic_ip_config_props.public_ipaddress = public_ip_if
      end
      nic_ip_config =
        Azure::ARM::Network::Models::NetworkInterfaceIpConfiguration.new
      nic_ip_config.name = Utils.get_component_name("privateip",@ci_id)
      nic_ip_config.properties = nic_ip_config_props
      OOLog.info("NIC IP name is: #{nic_ip_config.name}")
      nic_ip_config
    end

    # define the NIC object
    def define_network_interface(nic_ip_config)
      network_interface_props =
        Azure::ARM::Network::Models::NetworkInterfacePropertiesFormat.new
      network_interface_props.ip_configurations = [nic_ip_config]

      network_interface = Azure::ARM::Network::Models::NetworkInterface.new
      network_interface.location = @location
      network_interface.name = Utils.get_component_name("nic",@ci_id)
      network_interface.properties = network_interface_props

      OOLog.info("Network Interface name is: #{network_interface.name}")
      network_interface
    end

    def get(nic_name)
      begin
        OOLog.info("Fetching NIC '#{nic_name}' ")
        start_time = Time.now.to_i
        promise = @client.network_interfaces.get(@rg_name, nic_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("operation took #{duration} seconds")
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting NIC: #{nic_name}. Excpetion: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting NIC: #{nic_name}. Excpetion: #{ex.message}")
      end
    end

    # create or update the NIC
    def create_update(network_interface)
      begin
        OOLog.info("Updating NIC '#{network_interface.name}' ")
        start_time = Time.now.to_i
        promise =
          @client.network_interfaces.create_or_update(@rg_name,
                                                      network_interface.name,
                                                      network_interface)

        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
        OOLog.info("NIC '#{network_interface.name}' was updated in #{duration} seconds")
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error creating/updating NIC.  Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error creating/updating NIC.  Exception: #{ex.message}")
      end
    end

    # this manages building the network profile in preperation of creating
    # the vm.
    def build_network_profile(express_route_enabled, master_rg, pre_vnet, network_address, subnet_address_list, dns_list, ip_type, security_group_name)
      # get the objects needed to build the profile
      virtual_network = AzureNetwork::VirtualNetwork.new(creds, subscription)
      virtual_network.location = @location

      subnet_cls = AzureNetwork::Subnet.new(creds, subscription)

      # if the express route is enabled we will look for a preconfigured vnet
      if express_route_enabled == 'true'
        OOLog.info("Master resource group: '#{master_rg}'")
        OOLog.info("Pre VNET: '#{pre_vnet}'")
        #TODO add checks for master rg and preconf vnet
        virtual_network.name = pre_vnet
        # get the preconfigured vnet from Azure
        network = virtual_network.get(master_rg)
        # fail if we can't find a vnet
        OOLog.fatal('Expressroute requires preconfigured networks') if network.nil?
      else
        network_name = 'vnet_'+ network_address.gsub('.','_').gsub('/', '_')
        OOLog.info("Using RG: '#{@rg_name}' to find vnet: '#{network_name}'")
        virtual_network.name = network_name
        # network = virtual_network.get(@rg_name)
        if !virtual_network.exists?(@rg_name)
          # if network.nil?
          # set the network info on the object
          virtual_network.address = network_address
          virtual_network.sub_address = subnet_address_list
          virtual_network.dns_list = dns_list

          # build the network object
          new_vnet = virtual_network.build_network_object
          # create the vnet
          network = virtual_network.create_update(@rg_name, new_vnet)
        else
          network = virtual_network.get(@rg_name)
        end
      end

      subnetlist = network.body.properties.subnets
      # get the subnet to use for the network
      subnet =
          subnet_cls.get_subnet_with_available_ips(subnetlist,
                                                   express_route_enabled)

      # define the NIC ip config object
      nic_ip_config = define_nic_ip_config(ip_type, subnet)

      # define the nic
      network_interface = define_network_interface(nic_ip_config)

      #include the network securtiry group to the network interface
      nsg = AzureNetwork::NetworkSecurityGroup.new(creds, subscription)
      network_security_group = nsg.get(@rg_name, security_group_name)
      if !network_security_group.nil?
        network_interface.properties.network_security_group = network_security_group
      end

      # create the nic
      nic = create_update(network_interface)

      # retrieve and set the private ip
      @private_ip =
          nic.properties.ip_configurations[0].properties.private_ipaddress
      OOLog.info('Private IP is: ' + @private_ip)

      # set the nic id on the network_interface object
      network_interface.id = nic.id

      # create the network profile
      network_profile = Azure::ARM::Compute::Models::NetworkProfile.new
      # set the nic on the profile
      network_profile.network_interfaces = [network_interface]
      # set the profile on the object.
      @profile = network_profile
    end

  end
end
