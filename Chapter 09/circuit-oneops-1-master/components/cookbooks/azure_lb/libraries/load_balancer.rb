module AzureNetwork

  class LoadBalancer

    # include Azure::ARM::Network
    # include Azure::ARM::Network::Models

    attr_reader :client, :subscription_id

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
      @subscription_id = subscription_id
    end

    def get_subscription_load_balancers
      begin
        puts("Fetching load balancers from subscription")
        start_time = Time.now.to_i
        promise = @client.load_balancers.list_all()
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue MsRestAzure::AzureOperationError => e
        puts("Error fetching load balancers from subscription")
        puts("Error response: #{e.response}")
        puts("Error body: #{e.body}")
        result = Azure::ARM::Network::Models::LoadBalancerListResult.new
        return result
      end
    end

    def get_resource_group_load_balancers(resource_group_name)
      begin
        puts("Fetching load balancers from '#{resource_group_name}'")
        start_time = Time.now.to_i
        promise = @client.load_balancers.list(resource_group_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Error fetching load balancers from '#{resource_group_name}'")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        result = Azure::ARM::Network::Models::LoadBalancerListResult.new
        return result
      end
    end

    def get(resource_group_name, load_balancer_name)
      begin
        puts("Fetching load balancer '#{load_balancer_name}' from '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.load_balancers.get(resource_group_name, load_balancer_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        OOLog.info("Error getting LoadBalancer '#{load_balancer_name}' in ResourceGroup '#{resource_group_name}' ")
        OOLog.info("Error Code: #{e.body['error']['code']}")
        OOLog.info("Error Message: #{e.body['error']['message']}")

        result = Azure::ARM::Network::Models::LoadBalancer.new
        return result
      end
    end

    def create_update(location, resource_group_name, load_balancer_name, lb_props)
      begin
        lb = Azure::ARM::Network::Models::LoadBalancer.new
        lb.location = location
        lb.properties = lb_props

        puts("Creating/Updating load balancer '#{load_balancer_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.load_balancers.create_or_update(resource_group_name, load_balancer_name, lb)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        msg = "Error Code: #{e.body['error']['code']}"
        msg += "Error Message: #{e.body['error']['message']}"
        OOLog.fatal("Error creating/updating load balancer '#{load_balancer_name}'. #{msg} ")
      rescue => ex
        OOLog.fatal("Error creating/updating load balancer '#{load_balancer_name}'. #{ex.message} ")
      end
    end

    def delete(resource_group_name, load_balancer_name)
      begin
        puts("Deleting load balancer '#{load_balancer_name}' from '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.load_balancers.delete(resource_group_name, load_balancer_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        msg = "Error Code: #{e.body['error']['code']}"
        msg += "Error Message: #{e.body['error']['message']}"
        OOLog.fatal("Error deleting load balancer '#{load_balancer_name}'. #{msg} ")
      rescue => ex
        OOLog.fatal("Error deleting load balancer '#{load_balancer_name}'. #{ex.message} ")
      end
    end

    # ===== Static Methods =====

    def self.create_frontend_ipconfig(subscription_id, rg_name, lb_name, frontend_name, public_ip, subnet)
      # Frontend IP configuration – a Load balancer can include one or more frontend IP addresses,
      # otherwise known as a virtual IPs (VIPs). These IP addresses serve as ingress for the traffic.

      frontend_ipconfig_props = Azure::ARM::Network::Models::FrontendIpConfigurationPropertiesFormat.new

      ipallocation_method = Azure::ARM::Network::Models::IpAllocationMethod::Dynamic

      if public_ip.nil?
        frontend_ipconfig_props.private_ipallocation_method = ipallocation_method
        frontend_ipconfig_props.subnet = subnet
      else
        frontend_ipconfig_props.public_ipaddress = public_ip
        frontend_ipconfig_props.private_ipallocation_method = ipallocation_method
      end

      frontend_ipconfig_props.inbound_nat_rules = []
      frontend_ipconfig_props.load_balancing_rules = []

      frontend_ip_id = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/frontendIPConfigurations/#{frontend_name}"
      frontend_ipconfig = Azure::ARM::Network::Models::FrontendIpConfiguration.new
      frontend_ipconfig.id = frontend_ip_id
      frontend_ipconfig.name = frontend_name
      frontend_ipconfig.properties = frontend_ipconfig_props

      return frontend_ipconfig
    end

    def self.create_backend_address_pool(subscription_id, rg_name, lb_name, backend_address_pool_name)
      # Backend address pool – these are IP addresses associated with the
      # virtual machine Network Interface Card (NIC) to which load will be distributed.
      backend_address_props = Azure::ARM::Network::Models::BackendAddressPoolPropertiesFormat.new
      backend_address_props.load_balancing_rules = []
      backend_address_props.backend_ipconfigurations = []


      backend_id = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/backendAddressPools/#{backend_address_pool_name}"
      backend_address_pool = Azure::ARM::Network::Models::BackendAddressPool.new
      backend_address_pool.id = backend_id
      backend_address_pool.name = backend_address_pool_name
      backend_address_pool.properties = backend_address_props

      return backend_address_pool
    end

    def self.create_probe(subscription_id, rg_name, lb_name, probe_name, protocol, port, interval_secs, num_probes, request_path)
      # Probes – probes enable you to keep track of the health of VM instances.
      # If a health probe fails, the VM instance will be taken out of rotation automatically.
      probe_props = Azure::ARM::Network::Models::ProbePropertiesFormat.new
      probe_props.protocol = protocol
      probe_props.port = port   # 1 to 65535, inclusive.
      probe_props.request_path = request_path
      probe_props.number_of_probes = num_probes
      probe_props.interval_in_seconds = interval_secs
      probe_props.load_balancing_rules = []

      probe_id = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/probes/#{probe_name}"
      probe = Azure::ARM::Network::Models::Probe.new
      probe.id = probe_id
      probe.name = probe_name
      probe.properties = probe_props

      return probe
    end

    def self.create_lb_rule(lb_rule_name, load_distribution, protocol, frontend_port, backend_port, probe, frontend_ipconfig, backend_address_pool)
      # Load Balancing Rule: a rule property maps a given frontend IP and port combination to a set
      # of backend IP addresses and port combination.
      # With a single definition of a load balancer resource, you can define multiple load balancing rules,
      # each rule reflecting a combination of a frontend IP and port and backend IP and port associated with VMs.
      lb_rule_props = Azure::ARM::Network::Models::LoadBalancingRulePropertiesFormat.new
      lb_rule_props.probe = probe
      lb_rule_props.protocol = protocol
      lb_rule_props.backend_port = backend_port
      lb_rule_props.frontend_port = frontend_port
      lb_rule_props.enable_floating_ip = false
      lb_rule_props.idle_timeout_in_minutes = 5
      lb_rule_props.load_distribution = load_distribution
      lb_rule_props.backend_address_pool = backend_address_pool
      lb_rule_props.frontend_ipconfiguration = frontend_ipconfig

      lb_rule = Azure::ARM::Network::Models::LoadBalancingRule.new
      lb_rule.name = lb_rule_name
      lb_rule.properties = lb_rule_props

      return lb_rule
    end

    def self.create_inbound_nat_rule(subscription_id, resource_group_name, load_balance_name, nat_rule_name, idle_min, protocol, frontend_port, backend_port, frontend_ipconfig, backend_ip_config)
      # Inbound NAT rules – NAT rules defining the inbound traffic flowing through the frontend IP
      # and distributed to the back end IP.
      inbound_nat_rule_props = Azure::ARM::Network::Models::InboundNatRulePropertiesFormat.new
      inbound_nat_rule_props.protocol = protocol
      inbound_nat_rule_props.backend_port = backend_port
      inbound_nat_rule_props.frontend_port = frontend_port
      inbound_nat_rule_props.enable_floating_ip = false
      inbound_nat_rule_props.idle_timeout_in_minutes = idle_min
      inbound_nat_rule_props.frontend_ipconfiguration = frontend_ipconfig
      inbound_nat_rule_props.backend_ipconfiguration = backend_ip_config

      nat_rule_id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/loadBalancers/#{load_balance_name}/inboundNatRules/#{nat_rule_name}"
      in_nat_rule = Azure::ARM::Network::Models::InboundNatRule.new
      in_nat_rule.id = nat_rule_id
      in_nat_rule.name = nat_rule_name
      in_nat_rule.properties = inbound_nat_rule_props

      return in_nat_rule
    end

    def self.create_lb_props(frontend_ip_configs, backend_address_pools, lb_rules, nat_rules, probes)
      lb_props = Azure::ARM::Network::Models::LoadBalancerPropertiesFormat.new
      lb_props.probes = probes
      lb_props.frontend_ipconfigurations = frontend_ip_configs # Array<FrontendIpConfiguration>
      lb_props.backend_address_pools = backend_address_pools  # Array<BackendAddressPool>
      lb_props.load_balancing_rules = lb_rules # Array<LoadBalancingRule>
      lb_props.inbound_nat_rules = nat_rules # Array<InboundNatRule>

      return lb_props
    end

  end

end