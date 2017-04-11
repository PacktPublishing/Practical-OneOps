#
# Cookbook Name:: haproxy
# Recipe:: status
output = `service haproxy status`
Chef::Log.info("service haproxy status: #{output}")
