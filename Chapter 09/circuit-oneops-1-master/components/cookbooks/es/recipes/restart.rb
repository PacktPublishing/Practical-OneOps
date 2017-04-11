#
# Cookbook Name:: changeme
# Recipe:: restart
#
service "elasticsearch" do
  action :restart
end
