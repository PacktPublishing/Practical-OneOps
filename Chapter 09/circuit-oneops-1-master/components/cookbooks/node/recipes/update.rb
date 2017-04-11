#
# Cookbook Name:: nodejs
# Recipe:: update

Chef::Log.info("updating Node js.")
# Global attributes
include_recipe "node::default"
Chef::Log.info("restarting Node js.")


