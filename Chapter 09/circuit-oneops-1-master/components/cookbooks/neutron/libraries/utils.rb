def initialize_health_monitor(iprotocol, ecv_map, lb_name, iport)
  fail ArgumentError, 'ecv_map is invalid' if ecv_map.nil? || ecv_map.empty?

  begin
    ecv_map_list = JSON.parse(ecv_map)
    ecv_map_list.each do |ecv_port, ecv_path|
      if ecv_port == iport
        ecv_method, ecv_url = ecv_path.split(' ', 2)
        health_monitor = HealthMonitorModel.new(iprotocol, 5, 2, 3)
        health_monitor.label.name=lb_name + '-ecv'
        health_monitor.http_method=ecv_method
        health_monitor.url_path=ecv_url
        return health_monitor
      end
    end
    raise "No ECV defined for port #{iport}"
  end
end

def initialize_members(subnet_id, protocol_port)
  members = Array.new
  computes = node[:workorder][:payLoad][:DependsOn].select { |d| d[:ciClassName] =~ /Compute/ }
  computes.each do |compute|
    ip_address = compute["ciAttributes"]["private_ip"]
    if compute["ciAttributes"].has_key?("private_ipv6")
      ip_address = compute["ciAttributes"]["private_ipv6"]
      Chef::Log.info("ipv6 address: #{ip_address}")
    end

    member = MemberModel.new(ip_address, protocol_port, subnet_id)
    members.push(member)
  end
  return members
end

def initialize_pool(iprotocol, lb_algorithm, lb_name, members, health_monitor, stickiness, persistence_type)
  pool = PoolModel.new(iprotocol, lb_algorithm)
  pool.label.name=lb_name + '-pool'
  pool.members=members
  pool.health_monitor=health_monitor

  if stickiness == 'true'
    session_persistence = SessionPersistenceModel.new(persistence_type)
    pool.session_persistence = session_persistence.serialize_optional_parameters
  end

  return pool
end

def initialize_listener(vprotocol, vprotocol_port, lb_name, pool)
  listener = ListenerModel.new(vprotocol, vprotocol_port)
  listener.label.name=lb_name + '-listener'
  listener.pool=pool

  return listener
end

def initialize_loadbalancer(vip_subnet_id, provider, lb_name, listeners)
  loadbalancer = LoadbalancerModel.new(vip_subnet_id, provider)
  loadbalancer.label.name = lb_name
  loadbalancer.listeners=listeners

  return loadbalancer
end

def get_listeners_from_wo
  listeners = Array.new

  if node["loadbalancers"]
    raw_data = node['loadbalancers']
    raw_data.each do |listener|
      listeners.push(listener)
    end
  end

  return listeners
end

def get_dc_lb_names()
  platform_name = node.workorder.box.ciName
  environment_name = node.workorder.payLoad.Environment[0]["ciName"]
  assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
  org_name = node.workorder.payLoad.Organization[0]["ciName"]

  cloud_name = node.workorder.cloud.ciName
  dc = node.workorder.services["lb"][cloud_name][:ciAttributes][:gslb_site_dns_id]+"."
  dns_zone = node.workorder.services["dns"][cloud_name][:ciAttributes][:zone]
  dc_dns_zone = dc + dns_zone
  platform_ciId = node.workorder.box.ciId.to_s

  vnames = { }
  listeners = get_listeners_from_wo()
  listeners.each do |listener|
    frontend_port = listener[:vport]

    service_type = listener[:vprotocol]
    if service_type == "HTTPS"
      service_type = "SSL"
    end
    dc_lb_name = [platform_name, environment_name, assembly_name, org_name, dc_dns_zone].join(".") +
        '-'+service_type+"_"+frontend_port+"tcp-" + platform_ciId + "-lb"

    vnames[dc_lb_name] = nil
  end

  return vnames
end

