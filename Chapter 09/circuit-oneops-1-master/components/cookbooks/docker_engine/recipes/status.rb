# Cookbook Name:: docker_engine
# Attributes:: status
#
# Author : OneOps
# Apache License, Version 2.0

# Fix: Chef service resource is not working for status
execute 'systemctl status docker' do
  user 'root'
  group 'root'
end