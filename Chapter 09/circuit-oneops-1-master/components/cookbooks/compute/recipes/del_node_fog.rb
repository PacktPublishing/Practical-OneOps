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

#
# compute delete using fog
#

conn = node.iaas_provider

rfcCi = node.workorder.rfcCi
server = conn.servers.get(rfcCi[:ciAttributes][:instance_id])

ip = nil
if server != nil
    
  case node[:provider_class]
     
  when /ibm/
    if server.state != "Active"
      Chef::Log.info("state: "+server.state)                
    else
      Chef::Log.info("destroying server.")
      server.destroy     
      
      sleep 60
    end

    # wait 10min for server to be in Removed state, else keypair delete will fail w/ NotFound. usually takes 2-3min
    ok=false
    attempt=0
    max_attempts=10
    while !ok && attempt<max_attempts
      server = conn.servers.get(rfcCi[:ciAttributes][:instance_id])
      if (server.state == "Removed") 
        ok = true
      else
        Chef::Log.info("state: "+server.state)
        attempt += 1
        sleep 60
      end        
    end

    if !ok
      Chef::Log.error("server still not in Removed state after 10min. current state: "+server.state)
      exit 1
    end

  # To destroy/release a server from Aliyun, first stop it, then destroy/release it
  when /aliyun/
    if server['Status'] != "Running"
      Chef::Log.info("state: "+server['Status'])
    else
      Chef::Log.info("Stopping server")
      conn.stop_server(server['InstanceId'])
    end

    ok=false
    attempt=0
    max_attempts=20
    while !ok && attempt<max_attempts
      if (server['Status'] == "Stopped")
        ok = true
      else
        Chef::Log.info("waiting for the server in Stopped state")
        attempt += 1
        sleep 5
        a = conn.servers.get(server['InstanceId'])
        if !a.nil?
          server = a
        end
      end
    end

    if !ok
      Chef::Log.error("server still not in Stopped state. current state: " + server['Status'])
      exit 1
    end
    conn.delete_server(server['InstanceId'])

  else
    Chef::Log.info("destroying server: "+rfcCi[:ciAttributes][:instance_id])
    begin
      server.destroy     
    rescue Exception => e
      Chef::Log.info("delete failed: #{e.message}")
    end
    
    # retry for 2min for server to be deleted
    ok=false
    attempt=0
    max_attempts=6
    while !ok && attempt<max_attempts
      server = conn.servers.get(rfcCi[:ciAttributes][:instance_id])
      if (server.nil?) 
        ok = true
      elsif (node[:provider_class] == 'ec2' && server.state == "terminated")
        ok = true
      elsif (node[:provider_class] == 'openstack' && server.os_ext_sts_task_state == "deleting")
        # allow for queued up deletes
        Chef::Log.info("os_ext_sts_task_state: "+server.os_ext_sts_task_state)
        ok = true
      elsif (node[:provider_class] == 'rackspace' && server.state != "ACTIVE")
        ok = true
      else
        Chef::Log.info("state: "+server.state)
        attempt += 1
        server.destroy
        sleep 20
      end 
    end

    if !ok
      Chef::Log.error("server still not in removed after 7 attempts over 2min. current state: "+server.state)
      exit 1
    end
    
    
  end
  Chef::Log.info("waiting 10sec for openstack to update state")
  sleep 10
    
else
  Chef::Log.info("server already destroyed.")
end
