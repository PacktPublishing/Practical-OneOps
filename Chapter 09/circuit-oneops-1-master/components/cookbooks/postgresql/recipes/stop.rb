#
# Cookbook Name:: postgresql
# Recipe:: stop
#

service "postgresql-#{node["postgresql"]["version"]}" do
    pattern "postgres: writer"
    action :stop
end
