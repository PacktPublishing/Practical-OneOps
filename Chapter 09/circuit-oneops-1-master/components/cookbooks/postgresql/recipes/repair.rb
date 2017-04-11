#
# Cookbook Name:: postgresql
# Recipe:: repair
#

service "postgresql-#{node["postgresql"]["version"]}" do
  action :restart
end
