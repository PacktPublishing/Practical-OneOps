#
# gslb_vserver provider
#

def delete_gslb_vserver_by_name(gslb_vserver)
  conn = @new_resource.connection


  # binding from gslbvserver to gslbservice
  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/#{gslb_vserver}").body)        
    
  Chef::Log.debug("bindings: #{resp_obj.inspect}")
  
  binding = Array.new
  if !resp_obj["gslbvserver_gslbservice_binding"].nil?          
     binding = resp_obj["gslbvserver_gslbservice_binding"]
  end
  
  if binding.size != 0
    Chef::Log.info("not deleting #{gslb_vserver} because there are existing service bindings: #{binding.inspect}")
    return
  end

  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver/#{gslb_vserver}").body)        

  if resp_obj["message"] !~ /The GSLB vserver does not exist/
    
    Chef::Log.info( "gslb_vserver #{gslb_vserver}")
    
    resp_obj = JSON.parse(conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/gslbvserver/#{gslb_vserver}").body)
    
    if resp_obj["errorcode"] != 0
      if resp_obj["errorcode"] == 344
        Chef::Log.info("already deleted.")          
      else      
        Chef::Log.error("delete #{gslb_vserver} resp: #{resp_obj.inspect}")    
        exit 1      
      end
  
    else
      Chef::Log.info("delete #{gslb_vserver} resp: #{resp_obj.inspect}")
    end
    
    
  else 
    Chef::Log.info("#{gslb_vserver} already deleted.")
  end  
  
end

def clean_domain(domain, gslb_vserver_name)
  conn = @new_resource.connection
  
  Chef::Log.info("Getting gslb vserver domain binding for #{@new_resource.domain}")
  # need to use gslbvserver list to check domains - cannot call gslbvserver_domain_binding without a key/name    
  resp_obj = JSON.parse(conn.request(:method=>:get, 
    :path=>"/nitro/v1/config/gslbdomain_gslbvserver_binding/#{@new_resource.domain}").body)
  
  if !resp_obj.has_key?("gslbdomain_gslbvserver_binding")
    Chef::Log.info("no gslbdomain_gslbvserver_binding")
    return
  end
  
  resp_obj["gslbdomain_gslbvserver_binding"].each do |lbo|
  
    Chef::Log.info(lbo.inspect)
    gslbvs = lbo["vservername"]
      
    # delete old gslbvserver and binding
    resp_obj = JSON.parse(conn.request(
      :method=>:delete, 
      :path=>"/nitro/v1/config/gslbvserver/#{gslbvs}").body)

    if resp_obj["errorcode"] != 0
      Chef::Log.error( "domain bind delete #{@new_resource.domain} resp: #{resp_obj.inspect}")
      exit 1      
    else
      Chef::Log.info( "domain bind delete #{@new_resource.domain} resp: #{resp_obj.inspect}")
    end

  end   
end

def delete_gslb_vserver()
  # backwards compat
  delete_gslb_vserver_by_name(get_gslb_vserver_name)
  delete_gslb_vserver_by_name(get_gslb_vserver_name_by_platform)  
end


def get_gslb_vserver_name
  ci = node.workorder.payLoad.DependsOn[0]
  env_name = node.workorder.payLoad.environment[0]["ciName"]
  asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
  platform_name = node.workorder.box.ciName

  return [env_name, platform_name, ci["ciId"].to_s , "gslb"].join("-")  
end

def get_gslb_vserver_name_by_platform
  ci = node.workorder.box
  env_name = node.workorder.payLoad.environment[0]["ciName"]
  asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
  platform_name = node.workorder.box.ciName

  return [env_name, platform_name, asmb_name, ci["ciId"].to_s , "gslb"].join("-")
end

def create_gslb_vserver
  gslb_vserver_name = get_gslb_vserver_name
  conn = @new_resource.connection
  
  Chef::Log.info("gslb_vserver_name: #{gslb_vserver_name}")

  # check for gslb_service
  resp_obj = JSON.parse(conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/gslbvserver/#{gslb_vserver_name}").body)

  node.set["gslb_vserver_name"] = gslb_vserver_name
  
  # backwards compat
  if resp_obj["message"] =~ /The GSLB vserver does not exist/
  
    gslb_vserver_name = get_gslb_vserver_name_by_platform
    Chef::Log.info("platform gslb_vserver_name: #{gslb_vserver_name}")
  
    resp_obj = JSON.parse(conn.request(
      :method=>:get, 
      :path=>"/nitro/v1/config/gslbvserver/#{gslb_vserver_name}").body)  

    node.set["gslb_vserver_name"] = gslb_vserver_name

  end
      
  if resp_obj["message"] =~ /The GSLB vserver does not exist/
  
    Chef::Log.info( "domainname: #{@new_resource.domain}")
    
    gslb_vserver = {
      :name => gslb_vserver_name,
      :dnsrecordtype => @new_resource.dnsrecordtype,
      :servicetype =>  @new_resource.servicetype,
      :lbmethod => @new_resource.lbmethod
    }
    
    req = 'object= { "gslbvserver":'+JSON.dump(gslb_vserver)+'}'
      
    resp_obj = JSON.parse(conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/gslbvserver", 
      :body => URI::encode(req)).body)
  
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "post #{gslb_vserver_name} resp: #{resp_obj.inspect}")     
      exit 1      
    else
      Chef::Log.info( "post #{gslb_vserver_name} resp: #{resp_obj.inspect}")         
    end
    
  else
    if resp_obj["errorcode"] != 0 || !resp_obj.has_key?("gslbvserver") || resp_obj["gslbvserver"].size < 1      
      Chef::Log.info( "get gslbvserver #{gslb_vserver_name} returned: #{resp_obj.inspect}")
      exit 1
    end    
    
    Chef::Log.info( "gslb vserver #{gslb_vserver_name} exists.")
    ns_gslb_vserver = resp_obj["gslbvserver"][0]
    if ns_gslb_vserver["servicetype"] != @new_resource.servicetype
      Chef::Log.info("recreating due to gslb_vserver servicetype should be: #{@new_resource.servicetype} is: #{ns_gslb_vserver.inspect}")
      # binding from gslbvserver to gslbservice
      
      binding_resp_obj = JSON.parse(conn.request(
        :method=>:get,
        :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/#{gslb_vserver_name}").body)
    
      bindings = Array.new
      if !binding_resp_obj["gslbvserver_gslbservice_binding"].nil?
         bindings = binding_resp_obj["gslbvserver_gslbservice_binding"]
      end

      bindings.each do |binding|
        gslb_service_name = binding["servicename"]
        Chef::Log.info("deleting: gslb_service_name: #{gslb_service_name}")
        resp_obj = JSON.parse(conn.request(
        :method=>:delete, 
        :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)
      end
      delete_gslb_vserver
      sleep 2
      create_gslb_vserver      
    end

    gslb_vserver = {
      :name => gslb_vserver_name,
      :lbmethod => @new_resource.lbmethod
    }
    
    gslbvserver = JSON.dump(gslb_vserver)
    
    resp_obj = JSON.parse(conn.request(
      :method=>:put, 
      :path=>"/nitro/v1/config/gslbvserver/#{gslb_vserver_name}/", 
      :body => '{ "gslbvserver": ['+gslbvserver+'] }').body)

    if resp_obj["errorcode"] != 0
      Chef::Log.error( "put #{gslb_vserver_name} resp: #{resp_obj.inspect}")     
      exit 1      
    else
      Chef::Log.info( "put #{gslb_vserver_name} resp: #{resp_obj.inspect}")         
    end
          
  end
  
  puts "***RESULT:gslb_vnames={\"#{gslb_vserver_name}\":\"#{@new_resource.domain}\"}"
  
  if node.workorder.box.ciAttributes.is_active == "false"    
    Chef::Log.info("platform is_active == false - skipping domain binding")
    return
  end  
  
  
  
  binding = { :name => gslb_vserver_name, :domainname => @new_resource.domain }
  req = 'object= { "gslbvserver_domain_binding" : '+JSON.dump(binding)+ '}'

  # binding from service to lbvserver
  resp_obj = JSON.parse(conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver_domain_binding/#{gslb_vserver_name}",      
    :body => URI::encode(req)).body)  

    
  puts "bindings: #{resp_obj.inspect}"
  
  binding = Array.new
  if !resp_obj["gslbvserver_domain_binding"].nil?          
     binding = resp_obj["gslbvserver_domain_binding"].select{|v| v["domainname"] == @new_resource.domain }
  end
  
  if binding.size == 0
      
    resp_obj = JSON.parse(conn.request(
      :method=>:post, 
      :path=>"/nitro/v1/config/gslbvserver_domain_binding/#{gslb_vserver_name}?action=bind", 
      :body => URI::encode(req)).body)
      
    # if another gslb vserver has the domain, clear it
    if resp_obj["errorcode"] == 1842
      clean_domain(@new_resource.domain,gslb_vserver_name)
 
      # try bind again
      resp_obj = JSON.parse(conn.request(
        :method=>:post, 
        :path=>"/nitro/v1/config/gslbvserver_domain_binding/#{gslb_vserver_name}?action=bind", 
        :body => URI::encode(req)).body)
    
    end  
      
    
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "domain bind #{node.gslb_domain} resp: #{resp_obj.inspect}")
      exit 1      
    else
      Chef::Log.info( "domain bind #{node.gslb_domain} resp: #{resp_obj.inspect}")
    end
    
  else 
    Chef::Log.info( "bind exists: #{binding.inspect}")
  end
    
end


action :create do
   create_gslb_vserver
end

action :delete do
  delete_gslb_vserver
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerGslbVserver.new(@new_resource.name)
end

# Support whyrun
def whyrun_supported?
  true
end
