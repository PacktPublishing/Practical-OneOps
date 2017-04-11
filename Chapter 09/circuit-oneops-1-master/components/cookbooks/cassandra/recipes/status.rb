#
# Cookbook Name:: cassandra
# Recipe:: status
#
status_result = `service cassandra status`
Chef::Log.info("service cassandra status: "+status_result)
if status_result.to_i != 0
  Chef::Log.warn("service cassandra status result_code: "+status_result.to_i.to_s)
end 
ip = node.workorder.payLoad.ManagedVia.first['ciAttributes']['private_ip']
ring = `/opt/cassandra/bin/nodetool ring`.to_s
puts ring
puts "***RESULT:node_ip=#{ip}}"