#
# Cookbook Name:: cassandra
# Recipe:: stop_drain
#
execute "/opt/cassandra/bin/nodetool drain"

service "cassandra" do
  action :stop
end
