require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
set = node[:workorder][:rfcCi]

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")

#
# 1. construct the service command arguments to scale deployment back to 1
# service scale <container_name>=1
#

ruby_block "scale #{node[:container_name]}" do
  block do
    replicas = set[:ciAttributes][:replicas]
    service_scale = "service scale #{node[:container_name]}=1 2>&1"
    Chef::Log.info(service_scale)
    result = `#{docker} #{service_scale}`
    if $?.success?
      Chef::Log.info(result)
    else
      raise result
    end
  end
end

# TODO check if all replicas are deleted before proceeding
