require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")


ruby_block "delete service #{node[:container_name]}" do
  block do
    service_scale = "service rm #{node[:container_name]} 2>&1"
    Chef::Log.info(service_scale)
    result = `#{docker} #{service_scale}`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.error(result)
      if result.match("service #{node[:container_name]} not found")
        Chef::Log.info("Looks like service was already deleted")
      else
        raise
      end
    end
  end
end

# rmi custom build image from the docker swarm
if node[:image_type] != 'registry'
  ruby_block "delete image #{node[:image_name]}" do
    block do
      sleep 5
      Chef::Log.info("#{docker} rmi #{node[:image_name]}")
      result = `#{docker} rmi #{node[:image_name]} 2>&1`
      if $?.success?
        Chef::Log.info(result)
      else
        Chef::Log.error(result)
        if result.match("No such image: #{node[:image_name]}")
          Chef::Log.info("Looks like image was already deleted")
        else
          raise
        end
      end
    end
  end
end
