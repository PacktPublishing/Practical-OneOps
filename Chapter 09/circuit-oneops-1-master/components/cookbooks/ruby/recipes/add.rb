# Cookbook Name:: ruby
# Recipe:: add
#

if node[:ruby][:install_type]
  Chef::Log.info("Installation type #{node[:ruby][:install_type]} - running recipe ruby::#{node[:ruby][:install_type]}")
  include_recipe "ruby::#{node[:ruby][:install_type]}"
else
  Chef::Log.info("Installation type not specified - running default recipe ruby::repository")
  include_recipe "ruby::repository"
end


# check if it depends on a webserver and install modules
node.set[:ruby][:supported] = ["Apache","Nginx"]
node.set[:ruby][:webserver] = node.workorder.payLoad.DependsOn.select { |o| node[:ruby][:supported].include? o['ciClassName'].split('.').last }.first

if node.ruby.webserver != nil && node[:ruby][:webserver][:ciClassName]
  webserver_type = node[:ruby][:webserver][:ciClassName].split('.').last.downcase
  Chef::Log.info("Webserver type #{webserver_type} - running recipe ruby::#{webserver_type}")
  include_recipe "ruby::#{webserver_type}"
else
  Chef::Log.info("Webserver dependency not specified or not supported")
end
