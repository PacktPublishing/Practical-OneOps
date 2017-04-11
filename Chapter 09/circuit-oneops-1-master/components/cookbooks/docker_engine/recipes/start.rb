# Cookbook Name:: docker_engine
# Attributes:: start
#
# Author : OneOps
# Apache License, Version 2.0

docker_svc = node.docker_engine.service

service docker_svc do
  supports :status => true, :restart => true
  action :start
end
