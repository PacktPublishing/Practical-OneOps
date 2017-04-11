#
# Cookbook Name:: cassandra
# Recipe:: restart
#
execute "/opt/cassandra/bin/nodetool drain"

service "cassandra" do
  action :restart
end
