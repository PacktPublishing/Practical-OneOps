#
# adds a monitor which will be binded to service in add_services
#

n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)

include_recipe "netscaler::get_monitor_name"


node.monitors.each do |monitor|
  
  monitor_name = monitor[:monitor_name]
    
  if monitor_name =~ /generic-/
    Chef::Log.info("skipping delete monitor: #{monitor_name}")
    next
  end
    
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)        
  
  if resp_obj["message"] !~ /No such resource/

    type = monitor[:protocol].upcase

    # for some reason netscaler lbmonitor has a secure flag instead of using https proto
    if type == "HTTPS" || type == "SSL_BRIDGE"
      type = "HTTP"
    elsif type == "ANY"
      Chef::Log.info("skipping monitor delete for type #{type} - uses implicit/default monitor")
      next
    end
  
    # as of 10.x needs "?args=type:TYPE" added to the delete rest call path
    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}?args=type:#{type}").body)
  
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "delete monitor #{monitor_name} resp: #{resp_obj.inspect}")  
      exit 1
    else
      Chef::Log.info( "delete monitor #{monitor_name} resp: #{resp_obj.inspect}")    
    end    
    
  else
    Chef::Log.info( "monitor #{monitor_name} already deleted.")
  end  
    
end
