#
# Cookbook Name:: nodejs
# Recipe:: add
#

Chef::Log.info("Installing Node js.")
# Global attributes
include_recipe "nodejs::default"



