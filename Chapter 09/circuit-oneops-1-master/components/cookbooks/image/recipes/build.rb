rfcCi = node['workorder']['rfcCi']
image = rfcCi["ciAttributes"]

# set working directory
path = "#{Chef::Config['file_cache_path']}/#{rfcCi['ciId']}"
directory "#{path}" do
  recursive true
end

docker_build = "docker -H=127.0.0.1 build --force-rm --tag #{node[:image_name]}"
docker_push = "docker -H=127.0.0.1 push #{node[:image_name]}"

case image[:image_type]

when 'url'
  docker_build += " #{image['url']}"

when 'dockerfile'
  # download application package in the working directory
  if !image['url'].empty?
    Chef::Log.info("Downloading application package from #{image[:url]} to temporary path #{path}")
    artifact_deploy node[:image_name] do
      version node.workorder.dpmtRecordId.to_s
      artifact_location image[:url]
      deploy_to path
      shared_directories []
      owner 'ooadmin'
      group 'ooadmin'
      should_expand true
      remove_top_level_directory true
      force true
      remove_on_force true
      action :deploy
    end
  else
    directory "#{path}/current" do
      recursive true
    end
  end
  # create Dockerfile in the working directory
  if !image[:dockerfile].empty?
    dockerfile = "#{path}/current/Dockerfile"
    file "#{dockerfile}" do
      content image['dockerfile']
    end
  end
  docker_build += " ."
end

# execute build
ruby_block "build image #{node[:image_name]}" do
  block do
    Chef::Log.info(docker_build)
    result = `cd #{path}/current && #{docker_build} 2>&1`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.fatal(result)
      raise
    end
  end
end

# cleanup
directory "#{path}" do
  recursive true
  action :delete
end

# execute push
ruby_block "push image #{node[:image_name]}" do
  block do
    Chef::Log.info(docker_push)
    result = `#{docker_push} 2>&1`
    if $?.success?
      Chef::Log.info(result)
      puts "***RESULT:image_url="+node[:image_name]
    else
      raise result
    end
  end
end
