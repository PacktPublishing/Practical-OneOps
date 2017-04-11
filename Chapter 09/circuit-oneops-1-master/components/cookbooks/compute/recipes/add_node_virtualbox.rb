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
require 'xmlsimple'
require 'socket'
require 'timeout'

def get_nat_port
  port_closed=false
  port = 0
  while !port_closed do
    begin
      Timeout::timeout(5) do
        begin
          # using random in attempt to lower chance of issues when n-parallel computes are created
          # random port from 2000-65000
          port = rand 63000
          port += 2000
          ip = "127.0.0.1"
          Chef::Log.info("checking if hostport: #{port} is open")
          TCPSocket.new(ip, port).close
          Chef::Log.info("yep")
          port_closed = false
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          port_closed = true      
          Chef::Log.info("nope")
        end
      end
    rescue Timeout::Error
      Chef::Log.info("nope")
      port_closed = true
    end
  end  
  return port.to_s
end

def get_vbox_conf (vbox_conf_file)
  conf_xml = ''
  f = File.open(vbox_conf_file, "r") 
  f.each_line do |line|
    conf_xml += line
  end  
  return XmlSimple.xml_in(conf_xml)
end

def get_ip (nat_port)
  ip=''
  attempt = 0
  max_attempt = 5
  while ip.empty? && attempt < max_attempt do
     ip = `ssh -i /opt/oneops/inductor/vb.zone/key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@127.0.0.1 -p #{nat_port} "ifconfig eth0" | grep inet | awk '{ print $2 }' | head | sed 's/addr://'`.gsub("\n","")
     if ip.empty?
       sleep 10
     end
     attempt += 1
  end  
  Chef::Log.info("ip: #{ip}")
  return ip
end


token = node[:workorder][:token][:ciAttributes]
region = node[:workorder][:payLoad]["region"][0]["ciAttributes"]

conn = Fog::Compute.new({
  :provider => 'VirtualBox'
})

rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
server_name = rfcCi["ciName"]+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi["ciId"].to_s
  
regionCi = node["workorder"]["payLoad"]["region"][0]
region = regionCi["ciName"]
dns_domain = node["dns_domain"]
customer_domain = node["customer_domain"]

Chef::Log.info("compute::add -- name: "+server_name+" domain: "+customer_domain)  
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

# image_id - virtualbox uses name to get the image/vm to clone
ostype = rfcCi["ciAttributes"]["ostype"]
private_ip = ''

user = `logname`.chomp
# TODO: update for win/linux env
vbox_conf_file = "/Users/#{user}/VirtualBox VMs/#{server_name}/#{server_name}.vbox"

# get mac from existing config
if ::File.exists?(vbox_conf_file)
  vbox_conf = get_vbox_conf(vbox_conf_file)
  
  nat_port = vbox_conf["Machine"][0]["Hardware"][0]["Network"][0]["Adapter"][1]["NAT"][0]["Forwarding"][0]["hostport"]
  Chef::Log.info("nat port: #{nat_port}")
  
  ip = get_ip nat_port
  private_ip = ip
  
else
   
  cmd = "VBoxManage clonevm #{ostype} --name #{server_name}"
  result = `#{cmd}`
  Chef::Log.info("cmd: #{cmd} - result: #{result}")
  # clonevm creates a unique mac
  # mac_address = (1..6).map{"%0.2X"%rand(256)}.join('')
  # vbox_conf["Machine"][0]["Hardware"][0]["Network"][0]["Adapter"][0]["MACAddress"] = mac_address

  vbox_conf = get_vbox_conf(vbox_conf_file)
  
  nat_port = get_nat_port
  Chef::Log.info("nat port: #{nat_port}")
  vbox_conf["Machine"][0]["Hardware"][0]["Network"][0]["Adapter"][1]["NAT"][0]["Forwarding"][0]["hostport"] = nat_port
  vbox_xml_string = XmlSimple.xml_out(vbox_conf, 'RootName' => 'VirtualBox')
  ::File.open(vbox_conf_file, 'w') {|f| f.write(vbox_xml_string) }
    
  cmd = "VBoxManage registervm \"#{vbox_conf_file}\""
  result = `#{cmd}`
  Chef::Log.info("cmd: #{cmd} - result: #{result}")

  # shared dir/filesystem
  share_dir = "/Users/#{user}/vm-share/#{server_name}"
  `mkdir -p #{share_dir}`
  cmd = "VBoxManage sharedfolder add #{server_name} --name #{server_name} --hostpath \"#{share_dir}\""
  result = `#{cmd}`
  Chef::Log.info("cmd: #{cmd} - result: #{result}")
  # remote adds the fstab entry

  cmd = "VBoxManage startvm #{server_name}"
  result = `#{cmd}`
  Chef::Log.info("cmd: #{cmd} - result: #{result}")
  sleep 10
  ip = get_ip nat_port
  private_ip = ip
   
end   
  
# wait for ssh to be open
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

puts "***RESULT:private_ip="+ private_ip    
puts "***RESULT:instance_id="+ server_name  
