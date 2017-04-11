#
# Cookbook Name:: rabbitmq
# Recipe:: stop
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute
service "rabbitmq-server" do
  action :stop
end
