include_recipe "f5-bigip::get_monitor_name"
require_relative "../libraries/resource_ltm_monitor"
require_relative "../libraries/resource_config_sync"

begin
  ecv_map = JSON.parse(node.workorder.rfcCi.ciAttributes.ecv_map)
rescue Exception => e
  ecv_map = {}
end

node.old_monitor_names.each do |old_monitor_name|
	f5_ltm_monitor "#{old_monitor_name}" do
		monitor_name "#{old_monitor_name}"
		f5 "#{node.f5_host}"
		action :delete
	end
end

node.monitors.each do |mon|
if !ecv_map.has_key?(mon[:iport])
    ecv = "GET /"
  end
  iport = mon[:iport]
  ecv = ecv_map[iport]

  sg_name = mon[:sg_name]
  mon_name = mon[:monitor_name]
  protocol = mon[:protocol]
  mon_user_value = {'STYPE_SEND' => "#{ecv}", 'STYPE_RECEIVE' => '200'}
  case protocol
  when "http"
  	f5_ltm_monitor "#{mon_name}" do
  		monitor_name "#{mon_name}"
  		f5 "#{node.f5_host}"
  		dest_addr_type 'ATYPE_STAR_ADDRESS_EXPLICIT_PORT'
  		dest_addr_port iport.to_i
  		parent "/Common/#{protocol}"
  		user_values mon_user_value
      		action :create
      		notifies :run, "f5_config_sync[#{node.f5_host}]", :delayed
  	end
  when "tcp", "udp"
  	f5_ltm_monitor "#{mon_name}" do
  		f5 "#{node.f5_host}"
  		dest_addr_type 'ATYPE_STAR_ADDRESS_EXPLICIT_PORT'
  		dest_addr_port iport.to_i
  		parent "/Common/#{protocol}"
  		action :create
  		notifies :run, "f5_config_sync[#{node.f5_host}]", :delayed
  	end
  end
end


