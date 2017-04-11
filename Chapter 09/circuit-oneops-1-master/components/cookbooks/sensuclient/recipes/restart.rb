#
# Cookbook Name:: Sensuclient
# Recipe:: restart
#
#
# 

service "sensu-client" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end
