#
# server provider
#

def delete_by_name(server_key)

  Chef::Log.info("netscaler_server: #{server_key}")
  
  # check for server
  resp_obj = JSON.parse(@new_resource.connection.request(
    :method => :get, 
    :path => "/nitro/v1/config/server/#{server_key}").body)
    
  # delete if there
  if resp_obj["message"] !~ /No such resource/  
  
    resp_obj = JSON.parse(@new_resource.connection.request(
      :method => :delete, 
      :path => "/nitro/v1/config/server/#{server_key}").body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 1335
      Chef::Log.error( "delete #{server_key} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "delete #{server_key} resp: #{resp_obj.inspect}")
      node.set["gslb_has_changes"] = true
    end
    
  else 
    Chef::Log.info( "delete exists: #{resp_obj.inspect}")
  end
  
end



def create_server
  server_key = @new_resource.name
  Chef::Log.info("netscaler_server: #{server_key}")

  # check for server
  resp_obj = JSON.parse(@new_resource.connection.request(
    :method => :get, 
    :path => "/nitro/v1/config/server/#{server_key}").body)
  
  Chef::Log.info("get server response: #{resp_obj.inspect}")
  
  if resp_obj["message"] =~ /No such resource/
  
    server = {:name => server_key, :ipaddress => @new_resource.ipaddress }
  
    # ns nitro v1 api requires 'object=' string prefix
    req = 'object= { "server": '+JSON.dump(server)+'}'
 
    resp_obj = JSON.parse(@new_resource.connection.request(
      :method => :post, 
      :path =>"/nitro/v1/config/server", 
      :body => URI::encode(req)).body)
    
    if resp_obj["errorcode"] != 0

      if resp_obj["errorcode"] == 1335
        
        if resp_obj["message"].include?(server_key)
          Chef::Log.info( "server exists: #{resp_obj.inspect}")
        else
          #{"errorcode"=>1335, "message"=>"Server already exists [PyZDpVu1-5757594-2-10950000]"}
          if resp_obj["message"] =~ /exists \[(.*)\]/
            orphan = $1
            Chef::Log.info("cleaning up orphan: #{orphan}")
            delete_by_name(orphan)
            sleep 1
            create_server
          end
        end          
      else        
        Chef::Log.error( "post #{server_key} resp: #{resp_obj.inspect}")    
        exit 1      
      end        

    else
      Chef::Log.info( "post #{server_key} resp: #{resp_obj.inspect}")      
    end  

  else       
      Chef::Log.info( "server exists.")
      server_ip = resp_obj["server"][0]["ipaddress"]
      if server_ip != @new_resource.ipaddress
        Chef::Log.info("has ip: #{server_ip} should have: #{@new_resource.ipaddress}")
        delete_by_name(server_key)
        sleep 1
        create_server              
      end      
  end

end



action :create do
   create_server
end

action :delete do
  delete_by_name(@new_resource.name) 
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerServer.new(@new_resource.name)
end


