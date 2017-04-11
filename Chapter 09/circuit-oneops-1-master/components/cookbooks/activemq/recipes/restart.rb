# Cookbook Name:: activemq
# Recipe:: restart
#
include_recipe "activemq::stop"
include_recipe "activemq::start"
