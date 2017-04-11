#
## Cookbook Name:: f5
## Recipe:: setup
##
## Copyright 2013 Walmart Labs
#

cookbook_file "#{Chef::Config[:file_cache_path]}/f5-icontrol.gem" do
	source 'f5-icontrol-11.4.1.0.gem'
end

resources(:cookbook_file => "#{Chef::Config[:file_cache_path]}/f5-icontrol.gem").run_action(:create)


chef_gem 'f5-icontrol' do
	source "#{Chef::Config[:file_cache_path]}/f5-icontrol.gem"
	version '11.4.1.0'
end
