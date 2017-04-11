#
# Cookbook Name:: Sensuclient
# Recipe:: stop
#
#
#
service "sensu-client" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
