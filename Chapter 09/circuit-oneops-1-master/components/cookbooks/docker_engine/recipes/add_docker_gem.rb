# Cookbook Name:: docker_engine
# Attributes:: add_docker_gem
#
# Install docker remote API gem
#
# Author : OneOps
# Apache License, Version 2.0


# Install docker remote API client
gem_file = "/tmp/#{node.docker_engine.api_gem}"

cookbook_file gem_file do
  source node.docker_engine.api_gem
  owner 'root'
  group 'root'
  mode 0755
end

gem_package 'docker-api' do
  source gem_file
  options ('--no-ri  --no-rdoc')
  action :install
end