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

rfcCi = node[:workorder][:rfcCi]

cloud_name = node[:workorder][:cloud][:ciName]
cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

nspath = rfcCi["nsPath"].split("/").delete_if {|x| x.empty? || x == "bom" }
image_org = nspath.shift
image_version = nspath.pop
image_name = nspath.join('-')

docker_home = File.expand_path(cloud[:path])
docker_project = [ docker_home, rfcCi["nsPath"] ].join('/')

image = "#{image_org}/#{image_name}:#{image_version}"

node.set[:vm_cpu], node.set[:vm_memory] = node[:size_id].split("x")

Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

ruby_block "search #{node[:server_name]}" do
  block do
    node.set[:instance_id] = `docker ps -a | grep -E '#{node[:server_name]}' | awk '{print $1}'`.chomp
    if node[:instance_id].empty?
      node.set[:instance_id] = `docker run -P -h=#{node[:server_name]} --name=#{node[:server_name]} -t -d #{image}`.chomp
      Chef::Log.info("created instance id #{node[:instance_id]}")
    else
      Chef::Log.info("exists instance id #{node[:instance_id]}")
    end
  end
end

ruby_block "status #{node[:server_name]}" do
  block do
    instance = JSON.parse(`docker inspect #{node[:instance_id]}`)
    Chef::Log.debug("instance running state: #{instance.first['State']['Running'].inspect}")
    if instance.first['State']['Running']
      Chef::Log.info("running instance id #{node[:instance_id]}")
    else
      start = system("docker start #{node[:instance_id]}")
      if start
        Chef::Log.info("started instance id #{node[:instance_id]}")
      else
        Chef::Log.fatal!("failed to start instance id #{node[:instance_id]}")
      end
    end
  end
end

# output
ruby_block "inspect #{node[:server_name]}" do
  block do
    # this will only work with boot2docker
    # TODO: need to get host ip dynamically or from cloud service
    if ENV['DOCKER_HOST'] && docker_host = ENV['DOCKER_HOST'].match(/tcp:\/\/(.*):[0-9]+/)
      docker_host = docker_host[1]
    else
      docker_host = `ip addr show dev eth0 | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`.chop
    end
    instance = JSON.parse(`docker inspect #{node[:instance_id]}`)
    Chef::Log.info("instance #{instance.to_yaml}")
    # grab values from instance json
    Chef::Log.info("private_ip: "+instance.first['NetworkSettings']['IPAddress'])
    public_ip = "#{docker_host}:#{instance.first['NetworkSettings']['Ports']['22/tcp'][0]['HostPort']}"
    node.set["ip"] = public_ip
    Chef::Log.info("public_ip: "+public_ip)
    puts "***RESULT:private_ip="+instance.first['NetworkSettings']['IPAddress']
    puts "***RESULT:public_ip="+public_ip
    puts "***RESULT:instance_id="+node[:instance_id]
    puts "***RESULT:instance_name="+node[:server_name]
  end
end
