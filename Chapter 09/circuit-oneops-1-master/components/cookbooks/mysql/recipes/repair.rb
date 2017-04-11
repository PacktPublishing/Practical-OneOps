#
# Cookbook Name:: mysql
# Recipe:: repair

service "mysql" do
  action :restart
end
