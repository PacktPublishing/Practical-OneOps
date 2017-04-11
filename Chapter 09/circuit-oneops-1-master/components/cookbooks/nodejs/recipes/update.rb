#
# Cookbook Name:: nodejs
# Recipe:: update

Chef::Log.info("updating Node js.")
# Global attributes
include_recipe "nodejs::default"
Chef::Log.info("restarting Node js.")
include_recipe "nodejs::restart"


