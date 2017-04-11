#
# Cookbook Name:: zookeeper
# Recipe:: restart
#
#
# All rights reserved - Do Not Redistribute
service "zookeeper-server" do
  service_name 'zookeeper-server'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end
