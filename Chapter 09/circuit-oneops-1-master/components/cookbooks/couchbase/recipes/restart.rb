#
# Cookbook Name:: couchbase
# Recipe:: restart
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute
service "couchbase-server" do
  action :restart
end
