#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: restart_all
#
#

# this will do a cluster-wide bounce- script will determine what box its running
# on based on the resource name, then bounce its related service(s)
componentName = node.workorder.rfcCi.ciName
puts "component name is: #{componentName}"
case componentName
when /^prm/
    include_recipe "hadoop-yarn-v1::resourcemanager_stop"
    include_recipe "hadoop-yarn-v1::resourcemanager_start"
    include_recipe "hadoop-yarn-v1::namenode_stop"
    include_recipe "hadoop-yarn-v1::namenode_start"
when /^client/
    puts "i am a client and my ip is #{node.ipaddress}"
when /^dn/
    include_recipe "hadoop-yarn-v1::datanode_stop"
    include_recipe "hadoop-yarn-v1::datanode_start"
end
