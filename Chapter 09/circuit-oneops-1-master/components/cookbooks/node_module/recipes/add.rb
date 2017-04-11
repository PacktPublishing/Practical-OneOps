#
# Cookbook Name:: node_module
# Recipe:: add
#

Chef::Log.info("Installing node module")

module_name = node['node_module']['module_name']
app_name = node['node_module']['name']
module_version = node['node_module']['module_version']
as_user = node['node_module']['as_user']
server_root = node['node_module']['server_root']
node.set['node_module']['npm'] = `which npm`.strip
node.set['node_module']['node'] = `which node`.strip
install_options = node['node_module']['install_options'] || ''

["module_name","module_version","name"].each do |attr|
  exit_with_error "#{attr} has not been defined. please specify value to proceed" unless node.node_module.has_key?(attr)
  exit_with_error "#{attr} is empty. please specify value to proceed" if node["node_module"]["#{attr}"].empty?
end

execute "#{node['node_module']['npm']} install #{module_name}@#{module_version} #{install_options}" do
  cwd server_root
end

directory "#{server_root}/node_modules" do
  owner as_user
  group as_user
  recursive true
end

# create link app node module
link "#{server_root}/#{app_name}" do
  owner as_user
  group as_user
  to "#{server_root}/node_modules/#{module_name}"
end

service "nodejs" do
  service_name  "nodejs"
  case node["platform"]
  when "centos","redhat","fedora"
  supports :restart => true, :start => true, :stop => true,:status => true, :reload => true
  when "debian","ubuntu"
  supports :restart => true, :start => true, :stop => true,:status => true, :reload => true
  end
  action:nothing
end

template "/opt/nagios/libexec/check_proc_mem" do
  source "check_proc_mem.erb"
  owner "oneops"
  group "oneops"
  mode "0755"
end

directory "/log/nodejs" do
  owner as_user
  group as_user
  action :create
end

template "/etc/init.d/nodejs" do
  source "init.d.erb"
  mode "0755"
  notifies :enable, "service[nodejs]"
end
