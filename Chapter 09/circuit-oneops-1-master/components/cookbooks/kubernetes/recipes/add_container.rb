require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]
node.set[:container] = container[:ciAttributes]

namespace = node.workorder.rfcCi.nsPath.split("/")[1..3].join("-").to_s

#
# 1. construct the kubectl command arguments
#

# TODO move to template
#name
# env = JSON.parse(container[:ciAttributes][:env])
# ports = JSON.parse(container[:ciAttributes][:ports]).values.sort.uniq
# args = JSON.parse(container[:ciAttributes][:args])
# env.each { |key, value| kubectl.push("--env=\"#{key}=#{value}\"") } if !env.empty?
# kubectl.push(container[:ciAttributes][:command])
# kubectl.push(args) if !args.empty?


#
# 2. here we go, check if the pod is there and if not create a new one
#

deployment_yaml = "#{Chef::Config['file_cache_path']}/#{node[:container_name]}.deployment.yaml"
service_yaml = "#{Chef::Config['file_cache_path']}/#{node[:container_name]}.service.yaml"

template deployment_yaml do
  source "deployment.yaml.erb"
end

template service_yaml do
  source "service.yaml.erb"
end

ruby_block "container #{node[:container_name]}" do
  block do
    Chef::Log.info("kubectl get deployment -n #{namespace} -o json #{node[:container_name]}")
    deployment = `kubectl get deployment -n #{namespace} -o json #{node[:container_name]} 2>&1`
    Chef::Log.debug(deployment.inspect)
    if $?.success?
      deployment = JSON.parse(deployment)
      Chef::Log.info(deployment.inspect)
    else
      if deployment.match("not found")
        deployment = nil
      else
        Chef::Log.error(result)
        raise
      end
    end
    if !deployment.nil? && deployment.has_key?('metadata')
      Chef::Log.info("exists instance name #{node[:instance_name]}")
      # update deployment
      # TODO use kubectl patch for non-disruptive deployment update
      Chef::Log.info("kubectl replace -f #{deployment_yaml} -n #{namespace} --force 2>&1`")
      result = `kubectl replace -f #{deployment_yaml} -n #{namespace} 2>&1`
      if $?.success?
        Chef::Log.info("Replaced deployment #{result}")
        #node.set[:container_id] = result
      else
        Chef::Log.error(result)
        raise
      end
      # TODO use kubectl patch for non-disruptive service update
    else
      # create new deployment
      Chef::Log.info("kubectl create -f #{deployment_yaml} -n #{namespace} --record 2>&1`")
      result = `kubectl create -f #{deployment_yaml} -n #{namespace} --record 2>&1`
      if $?.success?
        Chef::Log.info("Created deployment #{result}")
        #node.set[:container_id] = result
      else
        Chef::Log.error(result)
        raise
      end
    end
  end
end

#
# 3. wait for the status to be rolled out
#
ruby_block "deployment #{node[:container_name]} status" do
  block do
    Chef::Log.info("kubectl rollout status deployment #{node[:container_name]} -n #{namespace} 2>&1`")
    result = `kubectl rollout status deployment #{node[:container_name]} -n #{namespace} 2>&1`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.error(result)
      raise
    end
  end
end

#
# 4. wait for the pod status to be Running and grab some information from the pod
#
ruby_block "pod #{node[:container_name]} status" do
  block do
    retries = 0
    complete = false
    while (!complete and retries < 30)
      done = 0
      pending = 0
      error = 0
      statuses = []
      pods = JSON.parse(`kubectl get pods -n #{namespace} -o json -l description=#{node[:container_name]} 2>&1`)
      if pods && pods.has_key?('items') && pods['items'].size > 0
        pods['items'].each do |pod|
          status = pod['status']['phase']
          case status
          when 'Running'
            done += 1
            #puts "***RESULT:instance_name=#{node[:instance_name]}"
            #puts "***RESULT:instance_uid=#{pod['metadata']['uid']}"
            #puts "***RESULT:container_id=#{pod['status']['containerStatuses'][0]['containerID']}"
            #puts "***RESULT:public_ip=#{pod['status']['hostIP']}"
            #puts "***RESULT:private_ip=#{pod['status']['podIP']}"
          when 'Pending'
            pending += 1
            statuses.push(pod['status'])
          else
            error += 1
            error_status = status
          end
        end
        if error > 0
          raise "FAILED: #{error_status}"
        elsif pending > 0
          Chef::Log.info("STATUS: done=#{done} pending=#{pending} retries=#{retries}")
          Chef::Log.debug(statuses.inspect)
          retries += 1
          sleep 5
        else
          complete = true
        end
      else
        # something went wrong with the get call
        Chef::Log.error(pods.inspect)
        raise
      end
    end
    if !complete
      raise "FAILED: #{statuses.inspect}"
    end
  end
end

#
# 5. expose as external service
#

ruby_block "expose deployment #{node[:container_name]}" do
  block do

    # check service
    service = `kubectl get service #{node[:container_name]} -n #{namespace} -o json 2>&1`
    if service.match("not found")
      # create new service
      Chef::Log.info("kubectl create -f #{service_yaml} -n #{namespace} --record 2>&1`")
      result = `kubectl create -f #{service_yaml} -n #{namespace} --record 2>&1`
      if $?.success?
        Chef::Log.info("Created service #{result}")
        #node.set[:container_id] = result
        service = `kubectl get service #{node[:container_name]} -n #{namespace} -o json 2>&1`
      else
        Chef::Log.error(result)
        raise
      end
    end

    # ports
    ports = {}
    service = JSON.parse(service)
    if service && service.has_key?('spec')
      service['spec']['ports'].each do |service_port|
        internal_port = service_port['port']
        ports[internal_port] = service_port['nodePort'].to_s
      end
      puts "***RESULT:node_ports="+JSON.generate(ports)
    else
      # something went wrong with the get call
      raise service.inspect
    end

    # nodes
    nodes = []
    nodes_result = JSON.parse(`kubectl get nodes -o json`)
    if nodes_result && nodes_result.has_key?('items')
      nodes_result['items'].each do |item|
        addresses = item['status']['addresses']
        puts "addrs: #{addresses}"
        addresses.each do |addr|
          next unless addr['type'] == 'InternalIP'
          nodes.push(addr['address'])
        end
      end
      puts "***RESULT:nodes="+JSON.generate(nodes)
    else
      # something went wrong with the get call
      raise nodes_result.inspect
    end

  end
end
