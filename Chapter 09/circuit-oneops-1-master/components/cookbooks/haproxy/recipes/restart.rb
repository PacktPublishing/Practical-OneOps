#
# Cookbook Name:: haproxy
# Recipe:: restart
#
service "haproxy" do
  action :restart
end
