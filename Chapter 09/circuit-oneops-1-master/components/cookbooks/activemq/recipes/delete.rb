#
# Cookbook Name:: activemq
# Recipe:: delete
#

service "activemq" do
  action [:stop, :disable]
end

