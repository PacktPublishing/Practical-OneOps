#
# Cookbook Name:: mysql
# Recipe:: stop
#
# All rights reserved - Do Not Redistribute
# status support doesn't work on ubuntu (returns 0 on server mysql status when its down), using pattern instead
service "mysql" do
  service_name value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")
  pattern "mysqld"
  supports :stop => true
  action :stop
end