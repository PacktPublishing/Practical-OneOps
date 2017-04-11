#
# Cookbook Name:: zookeeper
# Recipe:: stop
#
#

service "zookeeper-server" do
  service_name 'zookeeper-server'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
