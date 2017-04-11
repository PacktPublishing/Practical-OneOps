#
# Cookbook Name:: postgresql
# Recipe:: stop
#

service "governor" do
    action :stop
end
