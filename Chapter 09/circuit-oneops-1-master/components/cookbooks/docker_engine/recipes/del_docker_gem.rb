# Cookbook Name:: docker_engine
# Attributes:: del_docker_gem
#
# Uninstall docker remote API gem
#
# Author : OneOps
# Apache License, Version 2.0

# Uninstall docker remote API client
gem_file = "/tmp/#{node.docker_engine.api_gem}"

gem_package 'docker-api' do
  action :purge
  ignore_failure true
end

file gem_file do
  owner 'root'
  group 'root'
  action :delete
  ignore_failure true
end


