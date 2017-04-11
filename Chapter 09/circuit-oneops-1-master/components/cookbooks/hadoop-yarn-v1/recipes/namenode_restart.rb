#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: namenode_restart
#
#

include_recipe "hadoop-yarn-v1::namenode_stop"
include_recipe "hadoop-yarn-v1::namenode_start"
