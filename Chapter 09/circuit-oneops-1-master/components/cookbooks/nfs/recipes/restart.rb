#
# Cookbook Name:: nfs
# Recipe:: restart
#
service "nfs" do
  action :restart
end
