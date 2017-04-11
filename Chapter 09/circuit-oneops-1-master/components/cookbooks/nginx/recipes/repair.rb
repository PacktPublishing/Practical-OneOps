#
# Cookbook Name:: nginx
# Recipe:: repair
#

service "nginx" do
  action :restart
end
