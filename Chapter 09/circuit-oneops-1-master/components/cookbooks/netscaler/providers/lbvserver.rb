#
# lbvserver provider
#

def delete_by_name(lbvserver_name)

  Chef::Log.info("lbvserver_name: #{lbvserver_name}")
  
  # check for lbvserver
  resp_obj = JSON.parse(@new_resource.connection.request(
    :method => :get, 
    :path => "/nitro/v1/config/lbvserver/#{lbvserver_name}").body)
    
  # delete if there
  if resp_obj["message"] !~ /No such resource/  
  
    resp_obj = JSON.parse(@new_resource.connection.request(
      :method => :delete, 
      :path => "/nitro/v1/config/lbvserver/#{lbvserver_name}").body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 1335
      Chef::Log.error( "delete #{lbvserver_name} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "delete #{lbvserver_name} resp: #{resp_obj.inspect}")
    end
    
  else 
    Chef::Log.info( "delete exists: #{resp_obj.inspect}")
  end
  
end


def delete_server_by_ip(ip)

  Chef::Log.info("cleaning up fake server for gslbservice using ip: #{ip}")
  
  # check for lbvserver
  resp_obj = JSON.parse(@new_resource.connection.request(
    :method => :get, 
    :path => "/nitro/v1/config/server").body)
    
  resp_obj["server"].each do |server|
    if server["ipaddress"] == ip

      server_name = server["name"]
      
      resp_obj = JSON.parse(@new_resource.connection.request(
        :method => :delete, 
        :path => "/nitro/v1/config/server/#{server_name}").body)

      if resp_obj["errorcode"] != 0 
        Chef::Log.error( "delete #{server_name} resp: #{resp_obj.inspect}")    
        exit 1      
      else
        Chef::Log.info( "delete #{server_name} resp: #{resp_obj.inspect}")
      end
      return
      
    end
  end
    
end

def verify_ip (ip, lb_name)
  Chef::Log.info("getting all lbvserver for ip verify")
  if !node.has_key?("ns_first_time_ip") ||
     node.ns_first_time_ip.empty?
    return true
  end 
  
  lbs = []
  resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:get, 
      :read_timeout => 300,    
      :path=>"/nitro/v1/config/lbvserver").body)

  Chef::Log.info("verifying new ip ok #{resp_obj["lbvserver"].size} lbvserver")  
  lbs += resp_obj["lbvserver"]
  
  count = 0
  
  # lb match lb_name w/ id removed
  lb_match = lb_name.gsub(/\.com-.+$/,"")
  Chef::Log.info("verify lb_match: "+lb_match)
   
  lbs.each do |lb|
    if lb["ipv46"] == ip &&
       !lb["name"].include?(lb_match) 
      Chef::Log.info("lb: dup ip detection: #{lb.inspect}")
      return false
    end
  end  
  node.set["ns_first_time_ip"] = ""
  return true
end



def get_next_ip
  # use same ip for all new cloud-level vips ; dc-level vip will reset ns_lbvserver_ip
  return node["ns_lbvserver_ip"] if node.has_key?("ns_lbvserver_ip") && !node.ns_lbvserver_ip.empty?
    
  Chef::Log.info("getting all lbvserver for next ip")
  lbs = []
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :read_timeout => 300,    
    :path=>"/nitro/v1/config/lbvserver").body)

  if resp_obj.has_key?("lbvserver")
    Chef::Log.info("#{resp_obj["lbvserver"].size} lbvserver")
    lbs += resp_obj["lbvserver"]
  end
  
  lbvserver_ip = nil
  node.ns_ip_range.split(",").each do |range|
    ip = IPAddress::IPv4.new(range)    
    ip.each do |i|
      used = false
      ipstr = i.to_s
      lbs.each do |lb|
        if lb["ipv46"] == ipstr
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
  
end


def create_lbvserver
  lbvserver_name = @new_resource.name  
  Chef::Log.info("lbvserver_name: #{lbvserver_name}")
  if lbvserver_name.size > 127
    Chef::Log.error("lbvserver_name too long - max 127")
    exit 1
  end
  
  # check for server
  resp_obj = JSON.parse(@new_resource.connection.request(
    :method => :get, 
    :path => "/nitro/v1/config/lbvserver/#{lbvserver_name}").body)
  
  Chef::Log.info("get lbvserver response: #{resp_obj.inspect}")
  
  req = nil
  method = :put
      
  # check exists  
  if resp_obj["message"] =~ /No such resource/
    ip = @new_resource.ipv46
    # dont use ip from other az
    if node.has_key?("ns_conn_prev")
      Chef::Log.info("clearing ip")
      ip = nil
    end

    #Re-Use IP from Nitro Netscaler API
    lbparts = lbvserver_name.split("-")
    lbparts.pop #Remove lb
    lbparts.pop #Remove ciid
    lbparts.pop #Remove proto-port
    domain = lbparts.join("-")
    (node.loadbalancers+node.dcloadbalancers).each do |lb_vs|
      Chef::Log.debug("Entered Re-Use IP Logic")
      Chef::Log.debug("LB_VS: #{lb_vs.inspect}")
      Chef::Log.debug("DOMAIN: #{domain.inspect}")
      if lb_vs[:name].include?(domain)
        Chef::Log.debug("lbvserver match found")
        exist_resp_obj = JSON.parse(node.ns_conn.request(
        :method => :get, 
        :path => "/nitro/v1/config/lbvserver/#{lb_vs[:name]}").body)
        if exist_resp_obj["message"] !~ /No such resource/
          ip = exist_resp_obj["lbvserver"][0]["ipv46"]
          Chef::Log.debug("Reuse IP Found #{ip.inspect}, and Breaking")
          break
        end
      end
    end

    if ip.nil? || ip.empty?
      ip = get_next_ip
    end

    port = @new_resource.port
    if @new_resource.port == 'all'
      port = '*'
    end
    
    lbvserver_base = {
      :name => lbvserver_name,
      :ipv46 => ip,
      :port =>  port,
      :servicetype => @new_resource.servicetype,
      :lbmethod => @new_resource.lbmethod
    }

    custom_attrs = {}
    if node.workorder.rfcCi.ciAttributes.has_key?("lb_attrs")
      custom_attrs = JSON.parse(node.workorder.rfcCi.ciAttributes.lb_attrs)
    end
    lbvserver = lbvserver_base.merge(custom_attrs)

    if @new_resource.stickiness == "true"
      if ["SSL","HTTPS","HTTP"].include?(@new_resource.servicetype.upcase)
        lbvserver[:persistenceType] = "COOKIEINSERT"
      else
        lbvserver[:persistenceType] = "SOURCEIP"                
      end
      lbvserver[:timeout] = 360      
        
    end
    
    if !@new_resource.backupvserver.nil? && !@new_resource.backupvserver.empty?
      lbvserver[:backupVserver] = @new_resource.backupvserver
    end

    Chef::Log.info("new lbvserver: #{lbvserver.inspect}")

    req = URI::encode('object= { "lbvserver":'+JSON.dump(lbvserver)+'}' )    
    method = :post
    path = "/nitro/v1/config/lbvserver/"

    resp = JSON.parse(@new_resource.connection.request(
      :method=> method, 
      :path=> path, 
      :body => req).body)

    # cleanup orphan fake server for gslbservice
    case resp["errorcode"] 
    when 304
      delete_server_by_ip(ip)   
      
      resp = JSON.parse(@new_resource.connection.request(
        :method=> method, 
        :path=> path, 
        :body => req).body)
        
    # ip conflict
    when 273
      node.set["ns_lbvserver_ip"] = ""
      ip = get_next_ip
      lbvserver[:ipv46] = ip
      req = URI::encode('object= { "lbvserver":'+JSON.dump(lbvserver)+'}' )  
      Chef::Log.info("lbvserver create-ip_conflict using: #{req}")    
  
      resp = JSON.parse(@new_resource.connection.request(
        :method=> method, 
        :path=> path, 
        :body => req).body)
              
    end      
      
    if resp["errorcode"] != 0
      Chef::Log.error( "#{method} #{lbvserver_name} resp: #{resp.inspect}")    
      exit 1      
    else
      Chef::Log.info( "#{method} #{lbvserver_name} resp: #{resp.inspect}")    
    end

    
    # exit when > 2 ip for new lb vserver
    if verify_ip(ip,lbvserver_name)
      Chef::Log.info("ip: #{ip} verified")
    else
      Chef::Log.info("ip: #{ip} verify failed")     
      # remove self and exit - use workorder retry mechanism
      delete_by_name(lbvserver_name)
      # reduce contention
      sleep_time = rand(300)
      Chef::Log.info("sleeping rand(300) => #{sleep_time} due to ip contention")
      sleep(sleep_time)
      exit 1
    end
    
  else
    
    # reuse existing ip for other lbvservers
    node.set["ns_lbvserver_ip"] = resp_obj["lbvserver"][0]["ipv46"]
    
    Chef::Log.info( "lb exists: #{resp_obj.inspect}")
    lbvserver_base = {
      :name => lbvserver_name,
      :ipv46 => node.ns_lbvserver_ip,
      :lbmethod => @new_resource.lbmethod
    } 
    
    custom_attrs = {}
    if node.workorder.rfcCi.ciAttributes.has_key?("lb_attrs")
      custom_attrs = JSON.parse(node.workorder.rfcCi.ciAttributes.lb_attrs)
    end
    lbvserver = lbvserver_base.merge(custom_attrs)    
        
    if !@new_resource.backupvserver.nil? && !@new_resource.backupvserver.empty?
      lbvserver[:backupVserver] = @new_resource.backupvserver
    end

    if @new_resource.stickiness.nil?
      Chef::Log.info("Not updating persistenceType because it was not specified")
    else     
      
      if @new_resource.stickiness == "true"
          if node.workorder.rfcCi.ciAttributes.enable_lb_group == "false"
            lbvserver[:persistenceType] = @new_resource.persistence_type.upcase
            lbvserver[:timeout] = 360
          end
      else
        lbvserver[:persistenceType] = "NONE"
      end        
            
    end
               
    req = '{ "lbvserver": ['+JSON.dump(lbvserver)+'] }'
    path = "/nitro/v1/config/lbvserver/#{lbvserver_name}"

    Chef::Log.info("lbvserver update using: #{req}")    

    resp = JSON.parse(@new_resource.connection.request(
      :method=> method, 
      :path=> path, 
      :body => req).body)

    if resp["errorcode"] != 0
      Chef::Log.error( "#{method} #{lbvserver_name} resp: #{resp.inspect}")
      exit 1      
    else
      Chef::Log.info( "#{method} #{lbvserver_name} resp: #{resp.inspect}")    
    end
    
  end
  
  # disable insecure ssl
  if @new_resource.servicetype.upcase == "SSL"
    
    sslvserver = { 
      :vServerName => lbvserver_name,
      :ssl3 => "DISABLED"
    }
    req = '{ "sslvserver": ['+JSON.dump(sslvserver)+'] }'
  
    resp_obj = JSON.parse(@new_resource.connection.request(
      :method=>:put, 
      :path=>"/nitro/v1/config/sslvserver/#{lbvserver_name}", 
      :body => req).body)
    
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "sslv3 off resp: #{resp_obj.inspect}")
      exit 1      
    else
      Chef::Log.info( "sslv3 off resp: #{resp_obj.inspect}")
    end

  end


  # need to dance around the node reference
  existing_vservers = {}
  if node.has_key?("vnames")
    existing_vservers = node.vnames
  end
  vservers = {}.merge existing_vservers
  vservers[lbvserver_name] = node["ns_lbvserver_ip"]
  node.set["vnames"] = vservers

  

end


action :create do
   create_lbvserver
end

action :delete do
  delete_by_name(@new_resource.name) 
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerLbvserver.new(@new_resource.name)
end

