#
# Cookbook Name:: os
# Recipe:: status
#

Chef::Log.info(`/usr/bin/vmstat 5 3`)
