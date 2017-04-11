#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: nodemanager_restart
#
#

include_recipe "hadoop-yarn-v1::nodemanager_stop"
include_recipe "hadoop-yarn-v1::nodemanager_start"
