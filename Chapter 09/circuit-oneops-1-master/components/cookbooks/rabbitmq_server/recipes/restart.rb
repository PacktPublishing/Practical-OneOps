#
# Cookbook Name:: rabbitmq
# Recipe:: restart
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute
service "rabbitmq-server" do
  action :restart
end
