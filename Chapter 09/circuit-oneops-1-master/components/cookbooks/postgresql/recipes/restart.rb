#
# Cookbook Name:: postgresql
# Recipe:: restart
#

service "postgresql-#{node["postgresql"]["version"]}" do
  action :restart
end
