#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: datanode_restart
#
#

include_recipe "hadoop-yarn-v1::datanode_stop"
include_recipe "hadoop-yarn-v1::datanode_start"
