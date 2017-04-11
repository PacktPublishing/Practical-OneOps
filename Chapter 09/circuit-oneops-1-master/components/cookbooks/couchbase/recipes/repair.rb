#
# Cookbook Name:: couchbase
# Recipe:: repair
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute

# Using start instead of restart
# start does not have a negative impact if the service is already running
service "couchbase-server" do
  action :start
end
