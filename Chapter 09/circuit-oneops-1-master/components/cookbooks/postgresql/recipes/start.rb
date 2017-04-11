#
# Cookbook Name:: postgresql
# Recipe:: start
#

service "postgresql-#{node["postgresql"]["version"]}" do
  action :start
end
