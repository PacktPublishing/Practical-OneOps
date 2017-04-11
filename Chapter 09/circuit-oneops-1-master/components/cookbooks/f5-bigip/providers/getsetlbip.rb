#
# Cookbook Name:: f5-bigip
# provider:: getsetlbip
#

require 'excon'

include F5::Loader

def get_lbip(f5_ip)
  lbvserver_name = @new_resource.name
  lbparts = lbvserver_name.split("-")
  lbparts.pop #Remove lb
  lbparts.pop #Remove ciid
  lbparts.pop #Remove proto-port
  domain = lbparts.join("-")
  (node.loadbalancers+node.dcloadbalancers).each do |lb_vs|
    Chef::Log.debug("Entered Re-Use IP Logic")
    Chef::Log.debug("LB_VS: #{lb_vs.inspect}")
    Chef::Log.debug("DOMAIN: #{domain.inspect}")
    if lb_vs[:name].include?(domain) && lb_vs[:name].gsub('/Common/', '') != lbvserver_name &&  !search_virtual_server("#{f5_ip}").ltm.virtual_servers.find { |v| v.name =~ /(^|\/)#{lb_vs[:name]}$/ }.nil?
      Chef::Log.debug("lbvserver match found")
      lbvserver_ip = search_virtual_server("#{f5_ip}").ltm.virtual_servers.find { |v| v.name =~ /(^|\/)#{lb_vs[:name]}$/ }.destination_address.gsub('/Common/', '')
      node.set["ns_lbvserver_ip"] = lbvserver_ip
#      return search_virtual_server("#{f5_ip}").ltm.virtual_servers.find { |v| v.name =~ /(^|\/)#{lb_vs[:name]}$/ }.destination_address.gsub('/Common/', '')
      return lbvserver_ip
    end
  end


  vs = search_virtual_server("#{f5_ip}").ltm.virtual_servers.find { |v| v.name =~ /(^|\/)#{lbvserver_name}$/ }
  #conn = get_connection
  #Check if the lbserver exists or not
  lbvserver_ip = nil
  if vs.nil?
    vips = Array.new()
    #["10.10.10.10", "10.10.10.20", "10.10.10.15", "10.10.10.11", "11.11.11.0"] ==> IPs of Virtual Servers
    search_virtual_server("#{f5_ip}").ltm.virtual_servers.refresh_destination_address.find_all {|v| vips.push(v.destination_address.gsub('/Common/', ''))}
    node.ns_ip_range.split(",").each do |range|
      ip = IPAddress::IPv4.new(range)
      ip.each do |i|
        used = false
        ipstr = i.to_s
        vips.each do |lb|
          if lb == ipstr
            used = true
            break
          end
        end
         if !used
          lbvserver_ip = ipstr
          break
         end
      end
    end
    if lbvserver_ip.nil?
      msg = "no ip available in #{node.ns_ip_range}"
      Chef::Log.error(msg)
      puts "***FAULT:FATAL=#{msg}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
    Chef::Log.info("unused ip: "+lbvserver_ip)
    node.set["ns_lbvserver_ip"] = lbvserver_ip
    node.set["ns_first_time_ip"] = lbvserver_ip
    return lbvserver_ip
  else
    #11.11.11.0
    #search_virtual_server("#{f5_ip}").ltm.virtual_servers.find == 
    # #<F5::LoadBalancer::Ltm::VirtualServers::VirtualServer:0x00000003741ac8 @name="/Common/vs_new_user_defined", @destination_wildmask="255.255.255.255", @destination_address="/Common/11.11.11.0", 
    #  @destination_port=443, @type="RESOURCE_TYPE_POOL", @default_pool="/Common/new", @protocol="PROTOCOL_TCP", @profiles=[{"profile_context"=>"PROFILE_CONTEXT_TYPE_CLIENT", "profile_name"=>"/Common/clientssl-insecure-compatible"}, {"profile_context"=>"PROFILE_CONTEXT_TYPE_ALL", "profile_name"=>"/Common/http"}, {"profile_context"=>"PROFILE_CONTEXT_TYPE_SERVER", "profile_name"=>"/Common/serverssl-insecure-compatible"}, {"profile_context"=>"PROFILE_CONTEXT_TYPE_ALL", "profile_name"=>"/Common/tcp"}], @status=#<SOAP::Mapping::Object:0x3897508 {}availability_status="AVAILABILITY_STATUS_RED" {}enabled_status="ENABLED_STATUS_DISABLED" {}status_description="The children pool member(s) are down">, @vlans={"state"=>"STATE_DISABLED", "vlans"=>["/Common/vagrant_int"]}, @snat_type="SRC_TRANS_AUTOMAP", @snat_pool="", @default_persistence_profile=[{"profile_name"=>"/Common/cookie", "default_profile"=>true}], @fallback_persistence_profile="/Common/dest_addr", @rules=[#<SOAP::Mapping::Object:0x347bbb8 {}rule_name="/Common/_sys_https_redirect" {}priority=1>], @connection_limit=#<SOAP::Mapping::Object:0x3433228 {}high=0 {}low=443>>
    #vs = search_virtual_server("#{f5_ip}").ltm.virtual_servers.find { |v| v.name =~ /(^|\/)#{lbvserver_name}$/ }.destination_address.gsub('/Common/', '')
    node.set["ns_lbvserver_ip"] = vs.destination_address.gsub('/Common/', '')
    return vs.destination_address.gsub('/Common/', '')
  end

end  
  
action :create do
  ip = @new_resource.ipv46
  f5_ip = @new_resource.f5_ip
  if ip.nil? || ip.empty?
    get_lbip(f5_ip)
  else
    node.set["ns_lbvserver_ip"] = ip
  end
end

def load_current_resource
  @current_resource = Chef::Resource::F5BigipGetsetlbip.new(@new_resource.name)
end
