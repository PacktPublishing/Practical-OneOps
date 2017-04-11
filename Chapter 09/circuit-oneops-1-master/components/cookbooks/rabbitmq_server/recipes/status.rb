#
# Cookbook Name:: rabbitmq
# Recipe:: status
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute
Chef::Log.info(`service rabbitmq-server status`)
#service "rabbitmq-server" do
#  action :status
#end
