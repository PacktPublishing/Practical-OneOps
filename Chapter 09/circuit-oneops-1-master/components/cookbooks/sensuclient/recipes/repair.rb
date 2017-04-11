#
# Cookbook Name:: Sensuclient
# Recipe:: repair
#
#
#
service "sensu-client" do
  action :restart
end
