#
# Cookbook Name:: netscaler
# Recipe:: add_server
#
# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


def new_server (server_key,request)
    resp_obj = JSON.parse(node.ns_conn.request(
      :method => :post, 
      :path =>"/nitro/v1/config/server", 
      :body => URI::encode(request)).body)
  
    if resp_obj["errorcode"] != 0

      if resp_obj["errorcode"] == 1335
        
        if resp_obj["message"].include?(server_key)
          Chef::Log.info( "server exists: #{resp_obj.inspect}")
        else
          #{"errorcode"=>1335, "message"=>"Server already exists [PyZDpVu1-5757594-2-10950000]"}
          if resp_obj["message"] =~ /exists \[(.*)\]/
            orphan = $1
            Chef::Log.info("cleaning up orphan: #{orphan}")
            del_server(orphan)
            sleep 1
            new_server(server_key,request)
          end
        end          
      else        
        Chef::Log.error( "post #{server_key} resp: #{resp_obj.inspect}")    
        exit 1      
      end        

    else
      Chef::Log.info( "post #{server_key} resp: #{resp_obj.inspect}")
    end  
end

def del_server(server_key)
    resp_obj = JSON.parse(node.ns_conn.request(
      :method => :delete, 
      :path => "/nitro/v1/config/server/#{server_key}").body)
    
    if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 1335
      Chef::Log.error( "delete #{server_key} resp: #{resp_obj.inspect}")    
      exit 1      
    else
      Chef::Log.info( "delete #{server_key} resp: #{resp_obj.inspect}")
    end  
end


node.lb_members.each do |compute|

  ip = compute["ciAttributes"]["private_ip"] 
    
  server_key = ip
  next if ip.nil?

  # check for server using ip first for backwards compat
  resp_obj = JSON.parse(node.ns_conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/server/#{ip}").body)
  
  Chef::Log.debug("resp OBJ: #{resp_obj.inspect}")
  
  # add delete if there by ip
  if resp_obj["message"] !~ /No such resource/
    Chef::Log.info( "server exists: #{resp_obj.inspect}")    
    del_server(ip)        
  end

  
  if compute["ciAttributes"].has_key?("instance_name") &&
    !compute["ciAttributes"]["instance_name"].empty?
    
    server_key = compute["ciAttributes"]["instance_name"]
  end
  
  Chef::Log.info( "server_key: #{server_key}")
  
  
  # check for server
  resp_obj = JSON.parse(node.ns_conn.request(
    :method => :get, 
    :path => "/nitro/v1/config/server/#{server_key}").body)
  
  Chef::Log.debug(  "resp OBJ: #{resp_obj.inspect}")
  
  server = {:name => server_key, :ipaddress => ip }

  # ns nitro v1 api requires 'object=' string prefix
  req = 'object= { "server": '+JSON.dump(server)+'}'
  
  
  # add if not there
  if resp_obj["message"] =~ /No such resource/    
    Chef::Log.info( "server req: #{req}")
  
    new_server(server_key,req)
    
  else 
    Chef::Log.info( "server exists: #{resp_obj.inspect}")
    if resp_obj["server"][0]["ipaddress"] != ip
      Chef::Log.info( "server has old ip: " + resp_obj["server"][0]["ipaddress"] + " should be: #{ip}")
      
      # on compute::replace need to delete and add server w/ new ip
      del_server(server_key)
      new_server(server_key,req)
 
    end
    
  end

end