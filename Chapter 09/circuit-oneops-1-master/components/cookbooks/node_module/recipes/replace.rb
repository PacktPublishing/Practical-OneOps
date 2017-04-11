#
# Cookbook Name:: node_module
# Recipe:: replace

Chef::Log.info("Updating node module")
# Global attributes
include_recipe "node_module::default"
Chef::Log.info("restarting node module")
include_recipe "node_module::restart"
