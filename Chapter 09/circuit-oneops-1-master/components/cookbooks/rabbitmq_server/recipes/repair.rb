#
# Cookbook Name:: rabbitmq
# Recipe:: repair
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute
service "rabbitmq-server" do
  action :restart
end
