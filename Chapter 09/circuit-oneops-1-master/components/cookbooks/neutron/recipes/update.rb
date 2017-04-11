require File.expand_path('../../libraries/models/lbaas/loadbalancer_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/listener_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/pool_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/member_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/health_monitor_model', __FILE__)
require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../libraries/network_manager', __FILE__)
require File.expand_path('../../libraries/listener_manager', __FILE__)
require File.expand_path('../../libraries/pool_manager', __FILE__)
require File.expand_path('../../libraries/member_manager', __FILE__)
require File.expand_path('../../libraries/health_monitor_manager', __FILE__)
require File.expand_path('../../libraries/utils', __FILE__)


lb_attributes = node[:workorder][:rfcCi][:ciAttributes]
cloud_name = node[:workorder][:cloud][:ciName]
service_lb_attributes = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
tenant = TenantModel.new(service_lb_attributes[:endpoint],service_lb_attributes[:tenant],
                         service_lb_attributes[:username],service_lb_attributes[:password])
stickiness = lb_attributes[:stickiness]
persistence_type = lb_attributes[:persistence_type]
subnet_name = service_lb_attributes[:subnet_name]
network_manager = NetworkManager.new(tenant)
subnet_id = network_manager.get_subnet_id(subnet_name)

include_recipe "neutron::build_lb_name"
lb_name = node[:lb_name]

config_items_changed= node[:workorder][:rfcCi][:ciBaseAttributes] # config_items_changed is empty if there no configuration change in lb component

lb_manager = LoadbalancerManager.new(tenant)
listeners_manager = ListenerManager.new(tenant)

new_lb = lb_manager.get_loadbalancer(lb_name)
begin
  if !config_items_changed.empty? # old_config is empty if there no configuration change in lb component
    Chef::Log.info("lb_name : #{lb_name}")
    existing_lb = lb_manager.get_loadbalancer(lb_name)

    #handle changes in listeners only

    if config_items_changed.has_key?("listeners")
      #ciBaseAtrribute had old config setting, while ciAttriutes new config changes
      old = JSON.parse(node[:workorder][:rfcCi][:ciBaseAttributes][:listeners])
      new = JSON.parse(node[:workorder][:rfcCi][:ciAttributes][:listeners])
      #compare ciBaseAttribute and ciAttribute in WorkOrder to get the exact changes made by the user
      new_listeners_to_add = new - old
      listeners_to_cleanup = old - new

      Chef::Log.info("new_listeners_to_add:"+new_listeners_to_add.inspect)
      Chef::Log.info("listeners_to_cleanup:"+listeners_to_cleanup.inspect)

      listeners_to_cleanup.each do |listener|
        listener_properties =  listener.split(" ")
        vprotocol = listener_properties[0]
        vport = listener_properties[1]
        iprotocol = listener_properties[2]
        iport = listener_properties[3]
        existing_lb.listeners.each do |existing_listener|
          Chef::Log.info("#{existing_listener.protocol_port} == #{vport} && #{existing_listener.protocol} == #{vprotocol}}")
          if existing_listener.protocol_port.to_s == vport && existing_listener.protocol == vprotocol.upcase
            Chef::Log.info("Deleting listener #{existing_lb.id} ... ")
            listeners_manager.delete_listener(existing_lb.id,existing_listener)
          end
        end
      end

      new_listeners_to_add.each do |listener|
        listener_properties =  listener.split(" ")
        vprotocol = listener_properties[0].upcase
        vport = listener_properties[1]
        iprotocol = listener_properties[2].upcase
        iport = listener_properties[3]
        if vprotocol == 'HTTPS' and iprotocol == 'HTTPS'
          health_monitor = initialize_health_monitor('TCP', lb_attributes[:ecv_map], lb_name, iport)
        else
          health_monitor = initialize_health_monitor(iprotocol, lb_attributes[:ecv_map], lb_name, iport)
        end

        members = initialize_members(subnet_id, iport)
        pool = initialize_pool(iprotocol, lb_attributes[:lbmethod], lb_name, members, health_monitor, stickiness, persistence_type)
        new_listener = initialize_listener(vprotocol, vport, lb_name, pool)
        existing_lb = lb_manager.get_loadbalancer(lb_name)
        is_protocol_port_exist = false
        existing_lb.listeners.each do | exisiting_listener|
          if exisiting_listener.protocol_port.to_s == vport && exisiting_listener.protocol == vprotocol
            is_protocol_port_exist = true
          end
        end
        if !is_protocol_port_exist
          Chef::Log.info("adding new listners ...")
          listeners_manager.add_listener(existing_lb.id, new_listener)
        end
      end
    end

    #handle changes in ecv map only

    if config_items_changed.has_key?("ecv_map")
      healthmonitor_manager = HealthMonitorManager.new(tenant)
      ecv_map_list = JSON.parse(lb_attributes[:ecv_map])
      new_lb.listeners.each do | listener |
        ecv_map_list.each do |ecv_port, ecv_path|
          ecv_method, ecv_url = ecv_path.split(' ', 2)
          if ecv_port == listener.pool.members[0].protocol_port.to_s
            listener.pool.health_monitor.http_method=ecv_method
            listener.pool.health_monitor.url_path=ecv_url
            if listener.pool.health_monitor.type != "TCP"
              Chef::Log.info("Updating Health Monitor #{listener.pool.health_monitor.id}.... ")
              healthmonitor_manager.update_healthmonitor(new_lb.id, listener.pool.health_monitor.id, listener.pool.health_monitor)
            end
          end
        end
      end
    end

    #handle changes in stickiness & persistence_type  only

    if (config_items_changed.has_key?("stickiness") || config_items_changed.has_key?("persistence_type"))
      pool_manager = PoolManager.new(tenant)
      new_lb.listeners.each do | listener |
        if lb_attributes[:stickiness] == 'true'
          session_persistence = SessionPersistenceModel.new(lb_attributes[:persistence_type])
          listener.pool.session_persistence = session_persistence.serialize_optional_parameters
        else
          listener.pool.session_persistence = nil
        end
        pool_manager.update_pool(new_lb.id, listener.id, listener.pool.id, listener.pool)
      end
    end


    #handle changes in lbmethod attribute only

    if config_items_changed.has_key?("lbmethod")
      pool_manager = PoolManager.new(tenant)
      new_lb.listeners.each do | listener |
        listener.pool.lb_algorithm = lb_attributes[:lbmethod]
        Chef::Log.info("updating pool #{listener.pool.label.name} .....")
        if lb_attributes[:stickiness] == 'true'
          session_persistence = SessionPersistenceModel.new(lb_attributes[:persistence_type])
          listener.pool.session_persistence = session_persistence.serialize_optional_parameters
        end
        pool_manager.update_pool(new_lb.id, listener.id, listener.pool.id, listener.pool)
      end
    end
  end

  member_manager = MemberManager.new(tenant)
  computes = node[:workorder][:payLoad][:DependsOn].select { |d| d[:ciClassName] =~ /Compute/ }

  #handle changed when compute is replaced and ip of the compute changes.
  if !config_items_changed.has_key?("listeners")
    computes.each do |compute|
      new_ip_address = compute["ciAttributes"]["private_ip"]
      if compute["rfcAction"] == "replace"
        node.loadbalancers.each do |listener|
          Chef::Log.info ("listener:"+listener.inspect)
          iport = listener[:iport]
          new_member = MemberModel.new(new_ip_address, iport, subnet_id)
          new_lb.listeners.each do | listener_existing|
            Chef::Log.info("#{listener[:vport]} == #{listener_existing.protocol_port}")
            if listener[:vport] == listener_existing.protocol_port.to_s
              if !member_manager.is_member_exist(listener_existing.pool.id, new_ip_address)
                member_manager.add_member(new_lb.id, listener_existing.pool.id, new_member)
              end
            end
          end
        end
      end
    end
     if computes[0]["rfcAction"] == "replace"
        new_lb.listeners.each do | listener |
        listener.pool.members.each do | member |
          is_member_still_exist = false
          computes.each do | compute |
              if compute[:ciAttributes][:private_ip] == member.ip_address.to_s
              is_member_still_exist = true
              end
          end
          if is_member_still_exist == false
            member_manager.delete_member(listener.pool.id, member.id)
          end
        end
        end
     end
  end

rescue RuntimeError => ex

  Chef::Log.error(ex.inspect)
  Chef::Log.info(ex.message)
  actual_err = ex.message.split(":body")
  if actual_err[1] != nil
    error_msg = actual_err[1].split("\n")
    err= (error_msg[0].split("=>")[1])
    Chef::Log.info(error_msg[0])
    if error_msg[0] =~ /LoadBalancerListenerProtocolPortExists/
      error_msg[0] = "Please check your listener configuration, Two listeners with the same port detected. " + err
    end
    msg = error_msg[0]
  else
    msg = ex.message
  end
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new(msg)
  raise e
end

lb = lb_manager.get_loadbalancer(new_lb.id)
node.set[:lb_dns_name] = lb.vip_address
Chef::Log.info("VIP Address: " + lb.vip_address.to_s)
Chef::Log.info("Exiting neutron-lbaas update recipe.")

vnames = get_dc_lb_names()
vnames[lb_name] = nil
vnames.keys.each do |key|
  vnames[key] = lb.vip_address
 end


puts "***RESULT:vnames=" + vnames.to_json