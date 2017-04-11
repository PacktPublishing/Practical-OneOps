#
# Cookbook Name:: postgresql
# Recipe:: restart
#

service "governor" do
  action :restart
end
