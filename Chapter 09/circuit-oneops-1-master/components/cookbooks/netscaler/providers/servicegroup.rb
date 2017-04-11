#
# servicegroup
# 

def delete_by_name(sg_name)

  Chef::Log.info("sg_name: #{sg_name}")
  
  resp_obj = JSON.parse(@new_resource.connection.request(
       :method=>:get, 
       :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)
  
  if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 258
    Chef::Log.error( "get servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
    exit 1 
  end
  
  if resp_obj["message"] =~ /No such resource/
    Chef::Log.info("servicegroup #{sg_name} already deleted.")
  
  else
    Chef::Log.info("servicegroup #{sg_name} exists. #{resp_obj.inspect}")
  
    resp_obj = JSON.parse(@new_resource.connection.request(
         :method=>:delete, 
         :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 258
      Chef::Log.error( "get servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
      exit 1 
    end
    
  end
  
end




def create_servicegroup
 
  sg_name = @new_resource.name  
  protocol = @new_resource.protocol

  resp_obj = JSON.parse(@new_resource.connection.request(
       :method=>:get, 
       :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)
  
  if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 258
    Chef::Log.error( "get servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
    exit 1 
  end
  
  Chef::Log.info("get servicegroup: #{resp_obj.inspect}")
  
  # default settings then servicegroup_map used
  sg_base = { 
         "servicegroupname" => sg_name, 
         "servicetype" => protocol,
         "usip" => "NO",
         "cip" => "ENABLED",
         "cipHeader" => "NSC-client-ip",
         "TCPB" => "YES"
        }
  
  custom_attrs = {}
  if node.workorder.rfcCi.ciAttributes.has_key?("servicegroup_attrs")
    custom_attrs = JSON.parse(node.workorder.rfcCi.ciAttributes.servicegroup_attrs)
  end
  sg = sg_base.merge(custom_attrs)
  
  if resp_obj["message"] =~ /No such resource/
    
  
    req = 'object= { "servicegroup" : '+JSON.dump(sg)+ '}'
    
    resp_obj = JSON.parse(@new_resource.connection.request(
      :method=>:post, 
      :body => URI::encode(req),
      :path=>"/nitro/v1/config/servicegroup/").body)        
  
    if resp_obj["errorcode"] != 0
      Chef::Log.error( "post servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
      exit 1 
    else
      Chef::Log.info("ok post servicegroup: #{sg.inspect}")
    end
  
  
  else
    Chef::Log.info("servicegroup #{sg_name} exists. #{resp_obj.inspect}")
    existing_sg = resp_obj["servicegroup"][0]
    
    if protocol == existing_sg["servicetype"]
    
      sg.delete "servicetype"
      req = '{ "servicegroup": ['+JSON.dump(sg)+'] }'
      resp_obj = JSON.parse(@new_resource.connection.request(
        :method=>:put, 
        :body => req,
        :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)   
        
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "update servicegroup #{sg.inspect} failed... resp: #{resp_obj.inspect}")
        exit 1 
      else
        Chef::Log.info("ok update servicegroup: #{sg.inspect}")
      end

    else
      
      Chef::Log.info("servicetype change - existing: #{existing_sg['servicetype']} current: #{protocol} - need to delete and create the sg")
  
      resp_obj = JSON.parse(@new_resource.connection.request(
        :method=>:delete, 
        :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)        
    
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "delete servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
        exit 1 
      else
        Chef::Log.info("ok delete servicegroup: #{existing_sg.inspect}")
      end
  
      req = 'object= { "servicegroup" : '+JSON.dump(sg)+ '}'
      
      resp_obj = JSON.parse(@new_resource.connection.request(
        :method=>:post, 
        :body => URI::encode(req),
        :path=>"/nitro/v1/config/servicegroup/").body)        
    
      if resp_obj["errorcode"] != 0
        Chef::Log.error( "post servicegroup #{sg_name} failed... resp: #{resp_obj.inspect}")
        exit 1 
      else
        Chef::Log.info("ok post servicegroup: #{sg.inspect}")
      end
  
  
    end
  
    
  end


end


action :create do
   create_servicegroup
end

action :delete do
  delete_by_name(@new_resource.name) 
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerLbvserver.new(@new_resource.name)
end

