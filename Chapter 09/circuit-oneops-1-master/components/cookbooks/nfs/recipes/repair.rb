#
# Cookbook Name:: nfs
# Recipe:: repair

service "nfs" do
  action :restart
end
