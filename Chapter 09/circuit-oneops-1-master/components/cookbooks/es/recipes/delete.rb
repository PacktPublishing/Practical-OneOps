#
# Cookbook Name:: changeme
# Recipe:: delete
#

service "elasticsearch" do
  action [:disable, :stop]
end
