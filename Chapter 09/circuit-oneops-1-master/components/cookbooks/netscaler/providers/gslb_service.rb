#
# gslb_service provider
#
def delete_gslb_service_by_name(gslb_service_name)

  conn = @new_resource.connection

  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)        

  if resp_obj["message"] !~ /The GSLB service does not exist/
    
    Chef::Log.info( "gslb_service_name: #{gslb_service_name}")
    
    resp_obj = JSON.parse(conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)
    
    if resp_obj["errorcode"] != 0
      if resp_obj["errorcode"] == 344
        Chef::Log.info("already deleted.")          
      else      
        Chef::Log.error( "delete #{gslb_service_name} resp: #{resp_obj.inspect}")    
        exit 1      
      end
  
    else
      Chef::Log.info( "delete #{gslb_service_name} resp: #{resp_obj.inspect}")
    end
    node.set["gslb_has_changes"] = true  
    
  else 
    Chef::Log.info( "#{gslb_service_name} by platform already deleted.")
  end  

  
  # delete monitor for gslb service / vip
  cloud_name = node.workorder.cloud.ciName
  gdns_cloud_service = node.workorder.services['gdns'][cloud_name]
  dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
  vport = get_gslb_port
  monitor_name = node.workorder.box.ciId.to_s+"-#{vport}-#{dc_name}-gmon"
      
  mon_response  = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)
    
  mon_detail = []
  if mon_response.has_key?('lbmonitor') 
    mon_detail = mon_response['lbmonitor']
  end
      
  if mon_detail.size > 0
    type = mon_detail[0]['type']
      
    res_mon = JSON.parse(conn.request(
      :method=>:delete,
      :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}?args=type:#{type}").body)
    
    if res_mon['errorcode'] != 2131 && res_mon['errorcode'] != 0
      Chef::Log.error( "delete monitor #{monitor_name} resp: #{res_mon.inspect}")
      exit 1
    else
      Chef::Log.info( "delete monitor #{monitor_name} resp: #{res_mon.inspect}")
    	node.set["gslb_has_changes"] = true
    end
  else
    Chef::Log.info( "gslb service monitor #{monitor_name} already deleted.")
  end
end


def get_gslb_port
  # default / use 80 if exists
  gslb_port = 80
  lb = node.workorder.payLoad.lb.first
  listeners = JSON.parse( lb[:ciAttributes][:listeners] )
  listeners.each do |l|
    lb_attrs = l.split(" ") 
    gslb_protocol = lb_attrs[0].upcase
    gslb_port = lb_attrs[1].to_i
    break if gslb_protocol == "HTTP"
  end  
  return gslb_port
end


def delete_gslb_service()
  # backwards compat
  delete_gslb_service_by_name(get_gslb_service_name)
  delete_gslb_service_by_name(get_gslb_service_name_by_platform)  
end


def get_gslb_service_name
  env_name = node.workorder.payLoad.Environment[0]["ciName"]
  platform_name = node.workorder.box.ciName
  cloud_name = node.workorder.cloud.ciName
  ci = node.workorder.payLoad.DependsOn[0]
  asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
  gdns_cloud_service = node.workorder.services["gdns"][cloud_name]
  dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
  
  return [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
end

def get_gslb_service_name_by_platform
  env_name = node.workorder.payLoad.Environment[0]["ciName"]
  platform_name = node.workorder.box.ciName
  cloud_name = node.workorder.cloud.ciName
  ci = node.workorder.box
  asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
  gdns_cloud_service = node.workorder.services["gdns"][cloud_name]
  dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
  
  return [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
end


def clear_non_generic_monitor(conn,gslb_service_name,monitor_name)
  
  Chef::Log.info("delete monitor to migrate to generic monitor")
  gslbsvc_lbmon_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}").body)
    
  if !gslbsvc_lbmon_obj['gslbservice_lbmonitor_binding'].nil? && 
     !gslbsvc_lbmon_obj['gslbservice_lbmonitor_binding'].find{|glbmon| glbmon['monitor_name'] == monitor_name}.nil?
       
    binding = { :monitor_name => monitor_name, :servicename => gslb_service_name }
    Chef::Log.info("binding being deleted for migration to generic monitor: #{binding.inspect}")
    req = URI::encode('object={"params":{"action": "unbind"}, "gslbservice_lbmonitor_binding" : ' + JSON.dump(binding) + '}')
    resp_obj = JSON.parse(conn.request(
      :method=> :post,
      :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}",
      :body => req).body)

    if ![0,258].include?(resp_obj["errorcode"])
      Chef::Log.error( "delete bind #{binding.inspect} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "delete bind  #{binding.inspect} resp: #{resp_obj.inspect}")
    end
  end

  mon_response  = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)
    
  mon_detail = []
  if mon_response.has_key?('lbmonitor') 
    mon_detail = mon_response['lbmonitor']
  end
      
  if mon_detail.size > 0
    type = mon_detail[0]['type']
      
    res_mon = JSON.parse(conn.request(
      :method=>:delete,
      :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}?args=type:#{type}").body)
    
    if res_mon['errorcode'] != 2131 && res_mon['errorcode'] != 0
      Chef::Log.error( "delete monitor #{monitor_name} resp: #{res_mon.inspect}")
      exit 1
    else
      Chef::Log.info( "delete monitor #{monitor_name} resp: #{res_mon.inspect}")
    end    
  end     
end
  

def create_gslb_service
  ci = node.workorder.box
  gslb_service_name = get_gslb_service_name
  conn = @new_resource.connection
  cloud_name = node.workorder.cloud.ciName
  gdns_cloud_service = node.workorder.services["gdns"][cloud_name]
  dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
  
  Chef::Log.info("gslb_service_name: #{gslb_service_name}")

  # check for gslb_service
  resp_obj = JSON.parse(conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/gslbservice/#{gslb_service_name}").body)
  
  # backwards compat
  if resp_obj["message"] =~ /The GSLB service does not exist/
  
    gslb_service_name = get_gslb_service_name_by_platform
    Chef::Log.info("platform gslb_service_name: #{gslb_service_name}")
  
    resp_obj = JSON.parse(conn.request(
      :method=>:get, 
      :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)  
      
  end

  gslb_service = {
    :servicename => gslb_service_name,
    :servername => @new_resource.servername,
    :port =>  @new_resource.port,
    :servicetype => @new_resource.servicetype,
    :sitename => @new_resource.sitename,
    :state => @new_resource.state
  }

  lb = node.workorder.payLoad.lb.first
  if lb['ciAttributes']['stickiness'] == 'true'
    gslb_service[:sitepersistence] = "ConnectionProxy"
  end
  
  if resp_obj["message"] =~ /The GSLB service does not exist/    
  
    Chef::Log.info( "gslb_service_name: #{gslb_service_name}")
        
    puts "gslb_service: #{gslb_service.inspect}"
    req = 'object= { "gslbservice":'+JSON.dump(gslb_service)+'}'
        
    resp_obj = JSON.parse(conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/gslbservice", 
      :body => URI::encode(req)).body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 304
      Chef::Log.error( "post #{gslb_service_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      if resp_obj["errorcode"] == 304
        Chef::Log.info( "local lbvserver: #{resp_obj.inspect}")
        return
      end
      Chef::Log.info("post #{gslb_service_name} resp: #{resp_obj.inspect}")
      node.set["gslb_has_changes"] = true
    end   
    
  else 

    Chef::Log.info("gslb service exists: #{resp_obj.inspect}")
    existing_service = resp_obj["gslbservice"][0]
    
    gslb_service_ip = existing_service["ipaddress"]

    if @new_resource.serverip != gslb_service_ip || 
      lb['ciAttributes']['stickiness'] == 'true' ||
       existing_service["state"] !=  @new_resource.state ||
       existing_service["port"].to_i != @new_resource.port.to_i
      
      # put / update doesn't support state or ip change, need to delete then add
      delete_gslb_service
      sleep 2
      create_gslb_service
    end
      
       
  end
  
  # binding from gslbvserver to gslbservice
  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/#{@new_resource.gslb_vserver}").body)        
    
  if resp_obj.has_key?("gslbvserver_gslbservice_binding")
    bindings = resp_obj["gslbvserver_gslbservice_binding"]
    bindings.each do |binding|
     if binding["gslbboundsvctype"] != @new_resource.servicetype &&
        binding["servicetype"] != @new_resource.servicetype
        
        servicename = binding["servicename"]
        resp_obj = JSON.parse(conn.request(
              :method=>:delete,
              :path=>"/nitro/v1/config/gslbservice/#{servicename}").body)

        Chef::Log.info( "cleanup bind #{servicename} resp: #{resp_obj.inspect} due to: #{binding["servicetype"]} != #{@new_resource.servicetype}")
        Chef::Log.info( "binding: #{binding.inspect}")
        Chef::Log.info( "conn: #{conn.inspect}")

        if resp_obj["errorcode"] != 0
          Chef::Log.error( "cleanup bind #{servicename} resp: #{resp_obj.inspect}")
          exit 1
        end

      end
    end
  end

 
  bindings = Array.new
  if !resp_obj["gslbvserver_gslbservice_binding"].nil?
     bindings = resp_obj["gslbvserver_gslbservice_binding"].select{|v| v["servicename"] == gslb_service_name }
  end

  if bindings.size == 0  
    binding = { :name => @new_resource.gslb_vserver, :servicename => gslb_service_name }    
  
    req = 'object= { "gslbvserver_gslbservice_binding" : '+JSON.dump(binding)+ '}'
      
    resp_obj = JSON.parse(conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/", 
      :body => URI::encode(req)).body)
  
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "post bind #{gslb_service_name} resp: #{resp_obj.inspect}")
      exit 1      
    else
      Chef::Log.info( "post bind #{gslb_service_name} resp: #{resp_obj.inspect}")
      node.set["gslb_has_changes"] = true
    end
    
  else 
    Chef::Log.info( "bind exists: #{bindings.inspect}")
  end        
  
  # Adding GSLB Health Monitors
  begin
    lb = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Lb/ }.first
    ecv_map = JSON.parse(lb['ciAttributes']['ecv_map'])    
  rescue Exception => e
    ecv_map = {}
  end

  vport = @new_resource.port
  iport = @new_resource.iport
  vprotocol = @new_resource.servicetype.downcase
  if !ecv_map.has_key?(iport.to_s)
    ecv = "GET /"
  else
    ecv = ecv_map[iport.to_s]
  end
  monitor_name = ci["ciId"].to_s+"-#{vport}-#{dc_name}-gmon"
  if monitor_name.length > 31 #This can happen only becuase of dc_name rest all characters will max sum upto 24, including the max port no. allowed
    #monitor_name would take the 1st and last 2 characters of dc_name
    monitor_name = ci["ciId"].to_s+"-#{vport}-#{dc_name[0]}#{dc_name[/.{,#{2}}\z/m]}-gmon"
    dc_name = "#{dc_name[0]}#{dc_name[/.{,#{2}}\z/m]}"
  end
  
  # use generic monitors
  if ["get /","head /"].include?(ecv.downcase)
    # remove old one
    clear_non_generic_monitor(conn, gslb_service_name, monitor_name)
    # use generic one
    monitor_name = "generic-" + ecv.downcase.gsub(' ','-').gsub('/','slash')
  else
    # unbind generic
    resp_obj = JSON.parse(conn.request(:method=>:get, :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}").body)
    if resp_obj.has_key?('gslbservice_lbmonitor_binding')
      resp_obj['gslbservice_lbmonitor_binding'].each do |binding|
        if binding['monitor_name'] =~ /generic-/
          binding = { :monitor_name => binding['monitor_name'], :servicename => gslb_service_name }
          Chef::Log.info("binding being deleted: #{binding.inspect}")
          req = URI::encode('object={"params":{"action": "unbind"}, "gslbservice_lbmonitor_binding" : ' + JSON.dump(binding) + '}')
          resp_obj = JSON.parse(conn.request(
            :method=> :post,
            :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}",
            :body => req).body)
  
          if ![0,258].include?(resp_obj["errorcode"])
            Chef::Log.error( "delete bind #{binding.inspect} resp: #{resp_obj.inspect}")
            exit 1
          else
            Chef::Log.info( "delete bind  #{binding.inspect} resp: #{resp_obj.inspect}")
          end
        end
      end
    end
  end 
  
  monitor = {
    :monitorname => monitor_name,
    :type => 'HTTP',
    :respcode => ['200'],
    :httprequest => ecv
  }

  case vprotocol
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

  if vprotocol == 'ssl_bridge' || vprotocol == 'https' || vprotocol == 'ssl'
    monitor[:secure] = 'YES'
  else
    monitor[:secure] = 'NO'
  end

  req = nil
  method = :put

  resp_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbmonitor/#{monitor_name}").body)

  if resp_obj["message"] =~ /No such resource/
    method = :post
    path = "/nitro/v1/config/lbmonitor/"
    if monitor.has_key?(:httprequest) && !monitor[:httprequest].nil? &&
      monitor[:httprequest].include?("&")
      monitor[:httprequest] = "GET /"
    end
    req = URI::encode('object= { "lbmonitor":'+JSON.dump(monitor)+'}')
    node.set["gslb_has_changes"] = true
  else
    existing_monitor = resp_obj["lbmonitor"][0]
    Chef::Log.info("existing monitor: #{existing_monitor.inspect}")
    
    if existing_monitor["type"] != monitor[:type] && !monitor_name.start_with?("generic")
      Chef::Log.info("delete monitor due to different types: existing: #{existing_monitor['type']} current: #{monitor[:type]}")
      gslbsvc_lbmon_obj = JSON.parse(conn.request(
        :method=>:get,
        :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}").body)
        
      if !gslbsvc_lbmon_obj['gslbservice_lbmonitor_binding'].nil? && 
         !gslbsvc_lbmon_obj['gslbservice_lbmonitor_binding'].find{|glbmon| glbmon['monitor_name'] == monitor_name}.nil?
           
        binding = { :monitor_name => monitor_name, :servicename => gslb_service_name }
        Chef::Log.info("binding being deleted: #{binding.inspect}")
        req = URI::encode('object={"params":{"action": "unbind"}, "gslbservice_lbmonitor_binding" : ' + JSON.dump(binding) + '}')
        resp_obj = JSON.parse(conn.request(
          :method=> :post,
          :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}",
          :body => req).body)

        if ![0,258].include?(resp_obj["errorcode"])
          Chef::Log.error( "delete bind #{binding.inspect} resp: #{resp_obj.inspect}")
          exit 1
        else
          Chef::Log.info( "delete bind  #{binding.inspect} resp: #{resp_obj.inspect}")
        end
      end

      resp_obj = JSON.parse(conn.request(
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
      node.set["gslb_has_changes"] = true
    else
      # update
      Chef::Log.info( "monitor #{monitor_name} exists.")
      path = "/nitro/v1/config/lbmonitor/#{monitor_name}/"
      req = '{ "lbmonitor": ['+JSON.dump(monitor)+'] }'
    end
  end

  Chef::Log.info("#{method} #{monitor.inspect}")
  resp = conn.request(
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

    resp = conn.request(
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


  #Adding Bindings b/w GSLB Service and Monitor created above
  binding = { :monitor_name => monitor_name, :servicename => gslb_service_name }
  req = URI::encode('object={"params":{"action": "bind"}, "gslbservice_lbmonitor_binding" : ' + JSON.dump(binding) + '}')
  resp_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}").body)
  Chef::Log.info("gslbservice_lbmonitor_binding "+resp_obj.inspect)
  binding = Array.new
  if !resp_obj["gslbservice_lbmonitor_binding"].nil?
    binding = resp_obj["gslbservice_lbmonitor_binding"].select{|v| v["servicename"] == gslb_service_name && v["monitor_name"] == monitor_name }
  end

  if binding.size == 0
    resp_obj = JSON.parse(conn.request(
      :method=> :post,
      :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}",
      :body => req).body)
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "monitor put bind  resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "monitor post bind resp: #{resp_obj.inspect}")
      node.set["gslb_has_changes"] = true
    end
  else
    Chef::Log.info( "**** monitor bind exists ****")
  end
  #End Bindings b/w GSLB Service and Monitor created above

  # End GSLB Health Monitors



  # unbind the Old Monitors which were with naming convention :4501043-5432-gmon
  resp_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}").body)

  if resp_obj["errorcode"] == 0 && !resp_obj["gslbservice_lbmonitor_binding"][0].nil?
    #if !resp_obj["gslbservice_lbmonitor_binding"][0]["monitor_name"].include?dc_name
    resp_obj["gslbservice_lbmonitor_binding"].find_all{ |v| !v['monitor_name'].include?dc_name }.each do |old_mon|

        next if old_mon["monitor_name"].start_with?("generic")
        #binding = { :monitor_name => resp_obj["gslbservice_lbmonitor_binding"][0]["monitor_name"], :servicename => gslb_service_name }
        binding = { :monitor_name => old_mon["monitor_name"], :servicename => gslb_service_name }
        Chef::Log.info("binding being deleted: #{binding.inspect}")
        req = URI::encode('object={"params":{"action": "unbind"}, "gslbservice_lbmonitor_binding" : ' + JSON.dump(binding) + '}')
        resp_obj = JSON.parse(conn.request(
            :method=> :post,
            :path=>"/nitro/v1/config/gslbservice_lbmonitor_binding/#{gslb_service_name}",
            :body => req).body)
        if ![0,258].include?(resp_obj["errorcode"])
            Chef::Log.error( "delete bind #{binding.inspect} resp: #{resp_obj.inspect}")
            exit 1
        else
            Chef::Log.info( "delete bind  #{binding.inspect} resp: #{resp_obj.inspect}")
	    node.set["gslb_has_changes"] = true
        end
    end
  end
end


action :create do
   create_gslb_service
end

action :delete do
  delete_gslb_service
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerGslbService.new(@new_resource.name)
end


