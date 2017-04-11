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

require 'fog/aliyun'
require 'json'
require 'net/ssh'
require 'net/scp'

def clean_for_log( log )
  return log.gsub("\n"," ").gsub("<","").gsub(">","")
end

cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'aliyun',
  :aliyun_region_id => token[:region],
  :aliyun_zone_id => '', # "aliyun_zone_id" is not a required parameter
  :aliyun_url => token[:url],
  :aliyun_accesskey_id => token[:key],
  :aliyun_accesskey_secret => token[:secret]
})

rfcCi = node[:workorder][:rfcCi]
Chef::Log.debug("rfcCi attrs:"+rfcCi[:ciAttributes].inspect.gsub("\n"," "))

nsPathParts = rfcCi[:nsPath].split("/")
security_domain = nsPathParts[3]+'.'+nsPathParts[2]+'.'+nsPathParts[1]
Chef::Log.debug("security domain: "+ security_domain)


# size / flavor
sizemap = JSON.parse( token[:sizemap] )
size_id = sizemap[rfcCi[:ciAttributes][:size]]
Chef::Log.info("flavor: #{size_id}")

# image_id
#conn.images.all.each do |img|
# Chef::Log.info("img info: #{img.inspect}")
#end

#image = conn.images.get node[:image_id]
#Chef::Log.info("image: "+clean_for_log(image.inspect) )

Chef::Log.info("server_name: "+ node.server_name )

server = nil

if ! rfcCi["ciAttributes"]["instance_id"].nil? && 
   ! rfcCi["ciAttributes"]["instance_id"].empty? &&
   ! rfcCi["rfcAction"] == "replace"
     
  server = conn.servers.get(rfcCi["ciAttributes"]["instance_id"])
 
else
  #server = conn.servers.find { |i| i.name == node.server_name }
  conn.servers.all.each do |s|
  Chef::Log.info("server's name: #{s.inspect}")
    if s['InstanceName'] == node.server_name && (s['Status'] == "Running" || s['Status'] == "Stopped")
      server = s
      break
    end
  end
end


# security group
secgroup = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Secgroup/ }.first
Chef::Log.info("secgroup: #{secgroup[:ciAttributes][:group_name]}")


if server.nil?
  Chef::Log.info("creating server")
  availability_zone = nil
  compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
  if compute_service.has_key?("availability_zones") && !compute_service[:availability_zones].empty?
    availability_zones = JSON.parse(compute_service[:availability_zones])
  end
  
  if availability_zones.size > 0
    case node.workorder.box.ciAttributes.availability
    when "redundant"
      instance_index = node.workorder.rfcCi.ciName.split("-").last.to_i + node.workorder.box.ciId
      index = instance_index % availability_zones.size
      availability_zone = availability_zones[index]
    else
      Chef::Log.info("availability_zones: #{availability_zones}")
      random_index = rand(availability_zones.size)
      availability_zone = availability_zones[random_index]
    end
  end

  if availability_zone.nil?
    Chef::Log.error("#{cloud_name} does not have availability_zone defined or availability_zone is empty")
    exit 1
  end

  manifest_ci = node.workorder.payLoad.RealizedAs[0]
  
  if manifest_ci["ciAttributes"].has_key?("required_availability_zone") &&
    !manifest_ci["ciAttributes"]["required_availability_zone"].empty?
    
    availability_zone = manifest_ci["ciAttributes"]["required_availability_zone"]
    Chef::Log.info("using required_availability_zone: #{availability_zone}")
  end
 
  puts "***RESULT:availability_zone=#{availability_zone}"
       
  done = false
  retry_count = 0
  max_retry_count = 3
  while !done && retry_count < max_retry_count do
    retry_count += 1
      Chef::Log.info("secgroup =" + secgroup[:ciAttributes][:group_id])
      Chef::Log.info("sever name =" + node.server_name)
      Chef::Log.info("InternetChargeType = " + token[:internetchargetype])
      Chef::Log.info("InternetMaxBandwidthIn = " + token[:internetmaxbandwidthin])
      Chef::Log.info("InternetMaxBandwidthOut = " + token[:internetmaxbandwidthout])
      Chef::Log.info("Password = " + token[:password])
    begin
      server = conn.create_server(
                 node[:image_id],
                 secgroup[:ciAttributes][:group_id],
                 size_id,
                 :RegionId => token[:region],
                 :ZoneId => availability_zone,
                 :InstanceName => node.server_name,
                 :InternetChargeType => token[:internetchargetype],
                 :InternetMaxBandwidthIn => token[:internetmaxbandwidthin],
                 :InternetMaxBandwidthOut => token[:internetmaxbandwidthout],
                 :Password => token[:password]
               )
      done = true
    rescue Exception => e
      case e.message
      when /ZoneId provided does not exist/
        compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
        if compute_service.has_key?("availability_zones") && !compute_service[:availability_zones].empty?
          availability_zones = JSON.parse(compute_service[:availability_zones])
        end

        availability_zone = availability_zones[rand(availability_zones.size-1)]
        
        Chef::Log.info("hit: not supported in your requested Availability Zone, trying new az: #{availability_zone}")
        puts "***RESULT:availability_zone=#{availability_zone}"
        retry
                
      else
        Chef::Log.error(e.message)
        exit 1
      end

    end
  end
  Chef::Log.info("server is created: "+clean_for_log(server.inspect) )
  sleep 10
  instance_id = JSON.parse(server.body)['InstanceId']
  a = conn.servers.get(instance_id)
  server = a
else
  a = server
  server = nil
  server = conn.servers.get(a['InstanceId'])
  Chef::Log.info("running server: "+clean_for_log(server.inspect))
end


ok=false
attempt=0
max_attempts=30
while !ok && attempt<max_attempts
  if (server['Status'] == "Stopped")
    public_ip = conn.allocate_public_ip_address(server['InstanceId']).body
    ok = true
  else
    if (server['Status'] == "Running")
      conn.stop_server(server['InstanceId'])
    end
    Chef::Log.info("current status " + server['Status'])
    Chef::Log.info("waiting for the server in Stopped state")
    attempt += 1
    sleep 10
    a = conn.servers.get(server['InstanceId'])
    if !a.nil?
      server = a
    else
      Chef::Log.info("conn.servers.get returns null")
    end
  end
end

if !ok
  Chef::Log.error("server still not in Stopped state. current state: " + server['Status'])
  exit 1
end

ok=false
attempt=0
max_attempts=30
while !ok && attempt<max_attempts
  if (server['Status'] == "Running")
    ok = true
  else
    if (server['Status'] == "Stopped")
      conn.start_server(server['InstanceId'])
    end
    Chef::Log.info("current status " + server['Status'])
    Chef::Log.info("waiting for the server in Running state")
    attempt += 1
    sleep 10
    a = conn.servers.get(server['InstanceId'])
    if !a.nil?
      server = a
    end
  end
end

if !ok
  Chef::Log.error("server still not in Running state. current state: " + server['Status'])
  exit 1
end

Chef::Log.info("server is in Running state")

include_recipe "compute::ssh_port_wait"
node.set[:ip] = JSON.parse(public_ip)['IpAddress']
publickey = node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:public].to_s
Chef::Log.info("node_ip:" + node[:ip])
begin
  ssh = Net::SSH.start(node[:ip], "root", :password => token[:password])
  ssh.exec!("mkdir .ssh")
  File.open('/tmp/authorized_keys', 'w') { |file| file.write(publickey) }
  Net::SCP.upload!(node[:ip], "root", "/tmp/authorized_keys", ".ssh", :ssh => { :password => token[:password] })
  
  # in Aliyun ECS, "inet_protocols = all" will be a problem for postfix
  ssh.exec!("sed -i '/inet_protocols = all/c\inet_protocols = ipv4' /etc/postfix/main.cf")
  ssh.close
rescue
  Chef::Log.error("Unable to connect to #{node[:ip]} using root and #{token[:password]}")
  exit 1
end

`rm -f /tmp/authorized_keys`

if node.ostype =~ /centos/ &&
  node.set["use_initial_user"] = true
end

if !server['PrivateIpAddress'].nil?
  puts "***RESULT:private_ip="+server['PrivateIpAddress']
end
if !server['PublicIpAddress'].nil?
  puts "***RESULT:public_ip="+server['PublicIpAddress']['IpAddress'].first
end
puts "***RESULT:instance_id="+server['InstanceId']
puts "***RESULT:dns_record="+server['PublicIpAddress']['IpAddress'].first
puts "***node ip="+node[:ip]
