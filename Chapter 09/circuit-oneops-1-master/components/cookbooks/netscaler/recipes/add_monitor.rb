#
# adds a monitor which will be binded to service in add_services
#

include_recipe "netscaler::get_monitor_name"


# cleanup - unbind and delete old monitor
node.old_monitor_names.each do |old_monitor_name|

  cloud_name = node[:workorder][:cloud][:ciName]
  cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]

  ENV['HOME'] = '/tmp'
  require 'net/ssh'
  ssh = Net::SSH.start(cloud_service[:host], cloud_service[:username],
                       :password => cloud_service[:password], :paranoid => Net::SSH::Verifiers::Null.new)

  lbs = [] + node.cleanup_loadbalancers + node.loadbalancers
  lbs.each do  |lb|
    sg_name = lb[:sg_name]
    cmd = "unbind monitor #{old_monitor_name} #{sg_name}"
    Chef::Log.info("run: "+cmd)
    res = ssh.exec!(cmd)
    Chef::Log.info("result: "+res)

    if !res.include?("Done")
      message="unbind monitor returned: "+res
      Chef::Log.error( message )
      puts "***FAULT:FATAL="+message
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
  end
  ssh.close
  
  # skip deleting generic monitors
  next if old_monitor_name =~ /generic-/
  
  resp_obj = JSON.parse(node.ns_conn.request(:method=>:get,
  :path=>"/nitro/v1/config/lbmonitor/#{old_monitor_name}").body)
  unless resp_obj.has_key? "lbmonitor"
    Chef::Log.info("old monitor: #{old_monitor_name} already deleted.")
    next
  end
  mon_resp = resp_obj["lbmonitor"].first
  resp_obj = JSON.parse(node.ns_conn.request(:method=>:delete,
  :path=>"/nitro/v1/config/lbmonitor/#{old_monitor_name}?args=type:#{mon_resp['type']}").body)  

  if resp_obj["errorcode"] != 0
    Chef::Log.error( "delete #{old_monitor_name} resp: #{resp_obj.inspect}")
    exit 1
  else
    Chef::Log.info( "delete #{old_monitor_name} resp: #{resp_obj.inspect}")
  end  
  
end

begin
  ecv_map = JSON.parse(node.workorder.rfcCi.ciAttributes.ecv_map)
rescue Exception => e
  ecv_map = {}
end



begin
  ecv_map.keys.each do |port|
    next if port == 'all'
    port_int = Integer(port)
  end
rescue Exception => e
  Chef::Log.error("Invalid port. Each ECV map key must be integer port. keys: #{ecv_map.keys.inspect}")
  exit 1
end


node.monitors.each do |mon|
  
  if !ecv_map.has_key?(mon[:iport])
    ecv = "GET /"
  end
  iport = mon[:iport]
  ecv = ecv_map[iport]

  sg_name = mon[:sg_name]
  monitor_name = mon[:monitor_name]

  monitor = {
    :monitorname => monitor_name,
    :type => 'HTTP',
    :respcode => ['200'],
    :httprequest => ecv
  }
    
  # cleanup previous az
  if node.has_key?("ns_conn_prev")
    
    resp_obj = JSON.parse(node.ns_conn_prev.request(
      :method => :get, 
      :path =>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)        
    
    if resp_obj["message"] !~ /No such resource/
      type = resp_obj['lbmonitor'][0]['type']

      Chef::Log.info("removing monitor: #{monitor_name} from previous az / netscaler.")              
      resp_obj = JSON.parse(node.ns_conn_prev.request(
        :method => :delete,
        :path =>"/nitro/v1/config/lbmonitor/#{monitor_name}?args=type:#{type}").body)
      
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "delete monitor #{monitor_name} resp: #{resp_obj.inspect}")  
        exit 1
      else
        Chef::Log.info( "delete monitor #{monitor_name} resp: #{resp_obj.inspect}")    
      end
    else
      Chef::Log.info("already removed monitor: #{monitor_name} from previous az / netscaler.")
    end      
  end  


  protocol = mon[:protocol]
  case protocol
  when /tcp/
    monitor = {
      :monitorname => monitor_name,
      :type => 'TCP'
    }
  when "udp"
    monitor = {
      :monitorname => monitor_name,
      :type => 'UDP'
    }
  end

  if protocol == 'ssl_bridge' || protocol == 'https'
    monitor[:secure] = 'YES'
  else
    monitor[:secure] = 'NO'
  end

  req = nil
  method = :put

  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)

  if resp_obj["message"] =~ /No such resource/
    method = :post
    path = "/nitro/v1/config/lbmonitor/"
    # post needs uri encoding which messes up the request w/ ampersands
    # ... after the post call a put call is made to put the correct httprequest
    if monitor.has_key?(:httprequest) && !monitor[:httprequest].nil? &&
       monitor[:httprequest].include?("&")
       monitor[:httprequest] = "GET /"
    end
    req = URI::encode('object= { "lbmonitor":'+JSON.dump(monitor)+'}')
  else
    existing_monitor = resp_obj["lbmonitor"][0]

    Chef::Log.info("existing monitor: #{existing_monitor.inspect}")

    if existing_monitor["type"] != monitor[:type]
      Chef::Log.info("delete monitor due to different types: existing: #{existing_monitor['type']} current: #{monitor[:type]}")

      binding = { :monitorname => monitor_name, :servicegroupname => sg_name }
      Chef::Log.info("binding being deleted: #{binding.inspect}")
      req = 'object={"params":{"action": "unbind"}, "lbmonitor_servicegroup_binding" : ' + JSON.dump(binding) + '}'
      resp_obj = JSON.parse(node.ns_conn.request(
        :method=> :post,
        :path=>"/nitro/v1/config/lbmonitor_servicegroup_binding/#{monitor_name}",
        :body => req).body)

      if ![0,258].include?(resp_obj["errorcode"])
        Chef::Log.error( "delete bind #{binding.inspect} resp: #{resp_obj.inspect}")
        exit 1
      else
        Chef::Log.info( "delete bind  #{binding.inspect} resp: #{resp_obj.inspect}")
      end

      resp_obj = JSON.parse(node.ns_conn.request(
        :method=> :delete,
        :path=> "/nitro/v1/config/lbmonitor/#{monitor_name}?args=type:#{existing_monitor['type']}").body)

      if resp_obj["errorcode"] != 0
        Chef::Log.error( "delete #{monitor_name} resp: #{resp_obj.inspect}")
        exit 1
      else
        Chef::Log.info( "delete #{monitor_name} resp: #{resp_obj.inspect}")
      end

      # create new monitor w/ new type
      method = :post
      path = "/nitro/v1/config/lbmonitor/"
      if monitor.has_key?(:httprequest) && !monitor[:httprequest].nil? &&
         monitor[:httprequest].include?("&")
         monitor[:httprequest] = "GET /"
      end
      req = URI::encode('object= { "lbmonitor":'+JSON.dump(monitor)+'}')

    else
      # update
      Chef::Log.info( "monitor #{monitor_name} exists.")
      path = "/nitro/v1/config/lbmonitor/#{monitor_name}/"
      req = '{ "lbmonitor": ['+JSON.dump(monitor)+'] }'
    end

  end

  Chef::Log.info("#{method} #{monitor.inspect}")
  resp = node.ns_conn.request(
    :method=> method,
    :path=> path,
    :body => req)

  if !resp.nil? && resp.body != '(null)'
    resp_obj = JSON.parse(resp.body)
  else
    resp_obj = { "errorcode" => 0, :message => "ok", :monitor => monitor }
  end

  if resp_obj["errorcode"] != 0
    Chef::Log.error( "#{method} #{monitor_name} resp: #{resp_obj.inspect}")
    exit 1
  else
    Chef::Log.info( "#{method} #{monitor_name} resp: #{resp_obj.inspect}")
  end

  # workaround for netscaler post format / uri encoded ampersand issue
  if method == :post && !ecv.nil? && ecv.include?("&")
    monitor[:httprequest] = ecv

    resp = node.ns_conn.request(
    :method=> :put,
    :path=> "/nitro/v1/config/lbmonitor/#{monitor_name}/",
    :body => '{ "lbmonitor": ['+JSON.dump(monitor)+'] }')

    resp_obj = JSON.parse(resp.body)

    if resp_obj["errorcode"] != 0
      Chef::Log.error( "put #{monitor_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "put #{monitor_name} resp: #{resp_obj.inspect}")
    end
  end
end
