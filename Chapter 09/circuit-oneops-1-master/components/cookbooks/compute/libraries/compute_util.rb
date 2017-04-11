# Exit the chef application process with the given error message
#
# @param : msg -  Error message
#
def exit_with_error(msg)
  puts "***FAULT:FATAL=#{msg}"
  Chef::Application.fatal!(msg)
end

# get enabled network using the openstack compute cloud service
def get_enabled_network(compute_service,attempted_networks)

  has_sdn = true
  enabled_networks = []
  if compute_service.has_key?('enabled_networks')
    enabled_networks = JSON.parse(compute_service['enabled_networks'])
  end

  if enabled_networks.nil? || enabled_networks.empty?
    enabled_networks = [ compute_service['subnet'] ]
  end

  enabled_networks = enabled_networks - attempted_networks

  if enabled_networks.size == 0
    exit_with_error "no ip available in enabled networks for cloud #{node[:workorder][:cloud][:ciName]}. tried: #{attempted_networks} - escalate to openstack team"
  end

  network_name = enabled_networks.sample
  Chef::Log.info("network_name: "+network_name)

  # net_id for specifying network to use via subnet attr
  net_id = ''
  begin
    quantum = Fog::Network.new({
      :provider => 'OpenStack',
      :openstack_api_key => compute_service[:password],
      :openstack_username => compute_service[:username],
      :openstack_tenant => compute_service[:tenant],
      :openstack_auth_url => compute_service[:endpoint]
    })

    quantum.networks.each do |net|
      if net.name == network_name
        Chef::Log.info("network_id: "+net.id)
        net_id = net.id
        break
      end
    end
  rescue Exception => e
    Chef::Log.warn("no quantum or neutron networking installed")
    has_sdn = false
  end
   
  exit_with_error "Your #{node[:workorder][:cloud][:ciName]} cloud is configured to use network: #{compute_service[:subnet]} but is not found." if net_id.empty? && has_sdn

  return network_name, net_id
end
