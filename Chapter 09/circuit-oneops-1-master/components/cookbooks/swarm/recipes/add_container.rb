require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

network = node.workorder.rfcCi.nsPath.split("/")[1..3].join("-").to_s

# NOTE: to use a swarm running on the same server as the inductors create_args file
# cat /etc/systemd/system/docker.service.d/api.conf
# [Service]
# ExecStart=
# ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://127.0.0.1

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")

#
# 1. construct the docker service command arguments
#
# TODO waiting for implementation of namespaces or --network-alias for unique names
# currently using simple platform names as service names, but not unique globally
# https://github.com/docker/docker/issues/24787
# https://github.com/docker/docker/issues/25369
#

env = JSON.parse(container[:ciAttributes][:env])
ports = JSON.parse(container[:ciAttributes][:ports]).values.sort.uniq
args = JSON.parse(container[:ciAttributes][:args])

# create
create_args = [ "--name=#{node[:container_name]}" ]
create_args.push("--network=#{network}")
env.each { |key, value| create_args.push("-e=\"#{key}=#{value}\"") } if !env.empty?
ports.each { |port| create_args.push("-p=#{port}") } if !ports.empty?
create_args.push("#{node[:image_name]}")
create_args.push(container[:ciAttributes][:command])
create_args.push(args) if !args.empty?

# update
update_args = [ "--image=#{node[:image_name]}" ]
# NOTE there seems to be a bug when adding new ports with --publish-add
if container[:ciBaseAttributes].has_key?("ports")
  old_ports = JSON.parse(container[:ciBaseAttributes][:ports]).values.sort.uniq
  (ports - old_ports).each { |port| update_args.push("--publish-add=#{port}") }
  (old_ports - ports).each { |port| update_args.push("--publish-rm=#{port}") }
end
update_args.push("#{node[:container_name]}")
# TODO diff ports, envs, args

# inspect line
inspect = "service inspect #{node[:container_name]}"
Chef::Log.debug("INSPECT: #{docker} #{inspect}")


#
# 2. here we go, check if the service is there and if not create_args a new one
#
ruby_block "container #{node[:container_name]}" do
  block do
    service = JSON.parse(`#{docker} #{inspect}`.tr("\n"," "))
    # add check for exit status
    if service && service.kind_of?(Array)
      Chef::Log.debug("SERVICE: #{service.inspect}")
      if service.size > 0
        node.set[:instance_name] = service[0]['Spec']['Name']
        Chef::Log.info("exists instance name #{node[:instance_name]}")
        # update service
        Chef::Log.info("#{docker} service update #{update_args.join(' ')}")
        result = `#{docker} service update #{update_args.join(' ')} 2>&1`.chomp
        if $?.success?
          Chef::Log.info("Updated service instance #{result}")
          #node.set[:container_id] = result
        else
          Chef::Log.error(result)
          raise
        end
      else
        # create new service
        Chef::Log.info("#{docker} service create #{create_args.join(' ')}")
        result = `#{docker} service create #{create_args.join(' ')} 2>&1`.chomp
        if $?.success?
          Chef::Log.info("Created service instance #{result}")
          #node.set[:container_id] = result
        else
          Chef::Log.error(result)
          raise
        end
      end
    else
      # something went wrong with the get call
      raise service.inspect
    end
  end
end

#
# 3. wait for the status to be Running and grab some information from the service
#
status = "service ps -f 'desired-state=running' #{node[:container_name]} | grep Running | wc -l"
Chef::Log.debug("STATUS: #{docker} #{status}")

ruby_block "container #{node[:container_name]} status" do
  block do
    retries = 0
    complete = false
    while (!complete and retries < 60)
      running = `#{docker} #{status}`.chomp
      Chef::Log.debug("RUNNING: #{running.inspect}")
      if $?.success? && running.to_i > 0
        complete = true
        Chef::Log.info("container #{node[:instance_name]} status is Running")
      else
        Chef::Log.info("container #{node[:instance_name]} status is NOT Running yet")
        retries += 1
        sleep 5
      end
    end
    if !complete
      raise "service #{node[:instance_name]} failed to complete #{service.inspect}"
    end
  end
end

ruby_block "get published port for #{node[:container_name]}" do
  block do

    # ports
    service = JSON.parse(`#{docker} #{inspect}`)
    Chef::Log.debug("ports: #{service.first['Endpoint']['Ports']}")
    ports = {}
    service.first['Endpoint']['Ports'].each do |service_port|
      internal_port = service_port['TargetPort']
      ports[internal_port] = service_port['PublishedPort'].to_s
    end
    puts "***RESULT:ports="+JSON.generate(ports)

    # nodes
    nodes = Array.new
    nodes_list = `#{docker} node ls | grep -v ID`
    nodes_list.gsub!(/\r\n?/, "\n")
    nodes_list.each_line do |node|
      node_id = node.gsub(/\s+/m, ' ').strip.split(" ").first
      address = `#{docker} node inspect --format '{{ .ManagerStatus.Addr }}' #{node_id}`.split(':').first
      Chef::Log.debug("node: #{address}")
      nodes.push(address) if address =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
    end
    puts "***RESULT:nodes="+JSON.generate(nodes)

  end
end
