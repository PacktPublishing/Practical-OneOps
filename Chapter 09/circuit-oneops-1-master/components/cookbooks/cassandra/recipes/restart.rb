#
# Cookbook Name:: cassandra
# Recipe:: restart
#
service "cassandra" do
  supports :status => true, :start => true, :stop => true, :restart => true
  action :restart
end