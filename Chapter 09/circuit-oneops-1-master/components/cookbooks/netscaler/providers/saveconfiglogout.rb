#
# save (pushes the config to the standby) and logout
#

action :default do
  conn = @new_resource.connection || node.ns_conn

  # ns nitro v1 api needs this object=
  req = 'object= { "params":{"action":"save"}, "nsconfig":{} }'
  
  # add retry due to concurrency issue: Operation already in progress
  max_attempts = 10
  attempt = 0
  
  begin
    
    # get current and last saved config time
    resp_obj = JSON.parse(conn.request(:method=>:get, :path=>"/nitro/v1/config/nsconfig").body)
    nsconfig = resp_obj["nsconfig"]

    if attempt == 0
      base_ns_current_time = Time.parse(nsconfig["currentsytemtime"])
    end    
    ns_last_save_time = Time.parse(nsconfig["lastconfigsavetime"])            
    
    Chef::Log.info("base_ns_current_time: #{base_ns_current_time.to_i}")
    Chef::Log.info("ns_last_save_time: #{ns_last_save_time.to_i}")
    
    # don't save again if it was saved > 30sec after the initial try
    if ns_last_save_time.to_i > base_ns_current_time.to_i + 30
      Chef::Log.info("We started trying to save at: #{base_ns_current_time}")
      Chef::Log.info("config was saved at: #{ns_last_save_time} (ns time)")
      Chef::Log.info("skipping save due to a concurrent save from another workorder.")
    else
      start_call_time = Time.now
      resp = conn.request(
        :method=>:post,
        :path=>"/nitro/v1/config",
        :body => URI::encode(req)) 
          
      duration = Time.now.to_i - start_call_time.to_i
      Chef::Log.info("save call took: #{duration}sec")
      
      puts "save response status: #{resp.status}"
      resp_obj = JSON.parse(resp.body)
          
      if resp_obj["errorcode"] == 293
        wait_time = 10 * (attempt + 1)
        Chef::Log.error( "save inprogress waiting #{wait_time}sec ...")    
        sleep(wait_time)
        raise "Operation already in progress"
        
      elsif resp_obj["errorcode"] != 0
        raise "runtime error"    
        sleep 1
      else
        Chef::Log.info( "save ok. resp: #{resp_obj.inspect}")    
      end  
    end
    
  rescue Exception => e  
    attempt += 1
    Chef::Log.error("save failed. exception: #{e.message} resp: #{resp_obj.inspect} retry #{attempt}/#{max_attempts}")
    if attempt < max_attempts
      retry
    else
      exit 1
    end   
  end
  
  req = 'object= { "logout":{} }'
  
  resp = conn.request(
    :method=>:post,
    :path=>"/nitro/v1/config/logout",
    :body => URI::encode(req))
  
  puts "logout response status: #{resp.status}"
  resp_obj = JSON.parse(resp.body)
  
  if resp_obj["errorcode"] != 0
    Chef::Log.error( "logout failed. resp: #{resp_obj.inspect}")    
    exit 1      
  else
    Chef::Log.info( "logout ok. resp: #{resp_obj.inspect}")    
  end  
  
end



def load_current_resource
  @current_resource = Chef::Resource::NetscalerSaveconfiglogout.new(@new_resource.name)
end

