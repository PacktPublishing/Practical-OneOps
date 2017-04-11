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

require 'fog'
require 'json'

#
# SoftLayer Compute
#


cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
region = token[:region]

conn=nil
server=nil

conn = Fog::Compute.new(:provider => "softlayer",
 :softlayer_username => token[:username],
 :softlayer_api_key => token[:apikey]
)

rfcCi = node["workorder"]["rfcCi"]

customer_domain = node["customer_domain"]

Chef::Log.info("compute::add -- name:"+node.server_name+" domain:"+customer_domain+" provider: "+cloud_name)  
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

flavor = conn.flavors.get node.size_id
Chef::Log.info("flavor: "+flavor.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
  
Chef::Log.info("using image_id: #{node.image_id}")
image = conn.images.find { |i| i.id == node.image_id.to_s }   
Chef::Log.info("image: "+image.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))


server = nil
if ! rfcCi["ciAttributes"]["instance_id"].nil? && 
   ! rfcCi["ciAttributes"]["instance_id"].empty? &&
   ! rfcCi["rfcAction"] == "replace"
  server = conn.servers.get(rfcCi["ciAttributes"]["instance_id"])
else
  server = conn.servers.find { |i| i.name == node.server_name }
end

public_ip = nil
private_ip = nil

sshkey = conn.key_pairs.by_label(node[:kp_name])

if server.nil?
  Chef::Log.info("creating server")
  server = conn.servers.create :name => node.server_name,
                 :image_id => image.id,
                 :flavor_id => flavor.id,
		 :datacenter => token.datacenter,
		 :domain => customer_domain,
		 :key_pairs => [ sshkey ]
	
  server.wait_for { ready? }
    
  private_ip = server.private_ip_address
  public_ip = server.public_ip_address
  Chef::Log.info("server ready - public ip: " + public_ip)  
  
  # wait for ssh to be open
  require 'socket'
  require 'timeout'
  port_closed = true
  retry_count = 0
  max_retry_count = 5
  while port_closed && retry_count < max_retry_count do
    begin
      Timeout::timeout(5) do
        begin
          TCPSocket.new(ip, 22).close
          port_closed = false
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        end
      end
    rescue Timeout::Error
    end
    if port_closed
      Chef::Log.info("waiting for ssh port 10sec")
      sleep 10
    end 
    retry_count += 1
  end  

  # sleep 10sec more - needed 75% of the time
  sleep 10

# else server is populated
else
  public_ip = server.public_ip_address
  private_ip = server.private_ip_address
end
    
Chef::Log.info("server: "+server.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
Chef::Log.info("private_ip: "+private_ip)

node.set["ip"] = public_ip
