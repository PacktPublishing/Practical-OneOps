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
# rackspace compute add
#


cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
region = token[:region]

conn=nil
server=nil

conn = Fog::Compute::RackspaceV2.new({
  :rackspace_api_key => token[:password],
  :rackspace_username => token[:username]
})

rfcCi = node["workorder"]["rfcCi"]

#security_domain = get_security_domain(rfcCi["nsPath"])

customer_domain = node["customer_domain"]

Chef::Log.info("compute::add -- name:"+node.server_name+" domain:"+customer_domain+" provider: "+cloud_name)  
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

flavor = conn.flavors.get node.size_id.to_i
Chef::Log.info("flavor: "+flavor.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
  
Chef::Log.info("using image_id: #{node.image_id}")
image = conn.images.find { |i| i.id == node.image_id.to_s }   
Chef::Log.info("image: "+image.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))


server = nil
if ! rfcCi["ciAttributes"]["instance_id"].nil? && ! rfcCi["ciAttributes"]["instance_id"].empty?
  server = conn.servers.get(rfcCi["ciAttributes"]["instance_id"])
else
  server = conn.servers.find { |i| i.name == node.server_name }
end

# rackspace and openstack no like dots in keypair name
kp_name = node.kp_name.gsub(".","-")

if server.nil?
  Chef::Log.info("creating server name: #{node.server_name} keypair: #{kp_name}")
  server = conn.servers.create :name => node.server_name,
                 :keypair => kp_name,
                 :image_id => image.id,
                 :flavor_id => flavor.id
	
  server.wait_for { ready? }
    
  private_ip = server.addresses["private"][0]["addr"]
  ip = nil
  ips = server.addresses["public"]
  ips.each do |ip_addr|
    if ip_addr["version"] == 4
      ip = ip_addr["addr"]
    end
  end
  Chef::Log.info("server ready - public ip: "+ip)  
  
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
  private_ip = server.addresses["private"][0]["addr"]
end

    
Chef::Log.info("server: "+server.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
Chef::Log.info("private_ip: "+private_ip)

public_ip = ''
ips = server.addresses["public"]
ips.each do |ip_addr|
  if ip_addr["version"] == 4
    public_ip = ip_addr["addr"]
  end
end

puts "***RESULT:private_ip="+ private_ip    
puts "***RESULT:public_ip="+ public_ip    
puts "***RESULT:instance_id="+ server.id.to_s  
puts "***RESULT:dns_record="+public_ip
