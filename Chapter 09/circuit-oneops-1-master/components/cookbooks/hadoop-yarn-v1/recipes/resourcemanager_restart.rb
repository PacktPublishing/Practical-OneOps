#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: resourcemanager_restart
#
#

include_recipe "hadoop-yarn-v1::resourcemanager_stop"
include_recipe "hadoop-yarn-v1::resourcemanager_start"
