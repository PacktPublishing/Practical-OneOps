# Cookbook Name:: docker_engine
# Attributes:: delete
#
# Author : OneOps
# Apache License, Version 2.0

docker_root = node.docker_engine.root
docker_pkg = node.docker_engine.package
docker_svc = node.docker_engine.service

# Stop docker service.
service docker_svc do
  supports :status => true, :restart => true
  action :stop
end

# Remove the package.
package docker_pkg do
  action :remove
end

# To delete all images, containers, and volumes
directory docker_root do
  recursive true
  action :delete
end
