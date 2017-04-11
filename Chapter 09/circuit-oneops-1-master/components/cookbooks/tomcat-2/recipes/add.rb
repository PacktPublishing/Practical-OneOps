# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: tomcat-2
# Recipe:: add
# Purpose:: This recipe is used to do the initial setup of the Tomcat system
#     settings before the Tomcat binaries are installed onto the server.
#
# Copyright 2016, Walmart Stores Incorporated
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
###############################################################################
# Setup Tomcat User and Group
#   The tomcat_user and tomcat_group variables will be grabbed from the user
#     response in the metadata.rb file if different from the default values.
###############################################################################
include_recipe 'tomcat-2::generate_variables'
include_recipe 'tomcat-2::dump_attributes'

group "#{node['tomcat']['global']['tomcat_group']}" do
  action :create
end

user "#{node['tomcat']['global']['tomcat_user']}" do
  home "/home/#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  system true
  action :create
end

###############################################################################
# Setup server.xml variables
#   1 - Set the protocol type to org.apache.coyote.http11.Http11Protocol
#   2 - Set the advanced_NIO_connector_config to either the user-entered value
#       or the default value
#   3 - Log the advanced_NIO_connector_config value to the Chef log
#   4 - Define the tomcat_version_name
#   5 - Set the max and min threads for Tomcat's threadpool
#   6 - See if a keystore is required
#   7 - If keystore is required, log that it is and get values for keystore
#       settings.
#   8 - Check if both HTTP and HTTPS connectors are disabled
#       If so, warn the customer that the instance may not be reachable
#   9 - If HTTPS is enabled, define the TLS protocols desired.
#       If HTTPS is enabled and the user manually disabled all TLS protocols
#       from the UI, TLSv1.2 is enabled.
###############################################################################

depends_on_keystore = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Keystore/ }
if !depends_on_keystore.nil? && !depends_on_keystore.empty?
  Chef::Log.info("This does depend on keystore with filename: #{depends_on_keystore[0]['ciAttributes']['keystore_filename']} ")
  node.set['tomcat']['keystore_path'] = depends_on_keystore[0]['ciAttributes']['keystore_filename']
  node.set['tomcat']['keystore_pass'] = depends_on_keystore[0]['ciAttributes']['keystore_password']
  Chef::Log.info("Stashed keystore_path = #{node['tomcat']['keystore_path']}")
end

if node['tomcat']['server']['https_nio_connector_enabled'] == 'false' && node['tomcat']['server']['http_nio_connector_enabled'] == 'false'
    Chef::Log.warn('HTTP AND HTTPS ARE DISABLED. This may result in NO COMMUNICATION to the Tomcat instance.')
end

if node['tomcat']['server']['https_nio_connector_enabled'] == 'true'
  node.set['tomcat']['ssl_configured_protocols'] = ''
  if node['tomcat']['server']['tlsv11_protocol_enabled'] == 'true'
    node['tomcat']['ssl_configured_protocols'].concat('TLSv1.1,')
  end
  if node['tomcat']['server']['tlsv12_protocol_enabled'] == 'true'
    node['tomcat']['ssl_configured_protocols'].concat('TLSv1.2,')
  end
  node['tomcat']['ssl_configured_protocols'].chomp!(',')
  if node['tomcat']['ssl_configured_protocols'] == ''
    Chef::Log.warn('HTTPS is enabled, but all TLS protocols were disabled. Defaulting to TLSv1.2 only.')
    node.set['tomcat']['ssl_configured_protocols'] = 'TLSv1.2'
  end
end

###############################################################################
# Shutdown and Disable old service if it exists
###############################################################################

service 'disable old tomcat service' do
  provider Chef::Provider::Service::Systemd
  service_name 'tomcat'
  action [:stop, :disable]
  only_if { ::File.exist?('/lib/systemd/system/tomcat.service') }
end

file 'remove old tomcat service symlink' do
  path '/etc/systemd/system/tomcat.service'
  action :delete
  only_if { ::File.exist?('/etc/systemd/system/tomcat.service') }
end

file 'remove old tomcat service' do
  path '/lib/systemd/system/tomcat.service'
  action :delete
  only_if { ::File.exist?('/lib/systemd/system/tomcat.service') }
end



###############################################################################
# Run Install Cookbook for Tomcat Binaries
###############################################################################

include_recipe 'tomcat-2::add_binary'

###############################################################################
# Setup Log Rotation
#   The logrotate.d script and these cron jobs will clean out Tomcat logs
#   older than seven days old.
###############################################################################

template '/etc/logrotate.d/tomcat' do
  source 'logrotate.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0755'
end

cron 'logrotatecleanup' do
  minute '0'
  command "ls -t1 #{node['tomcat']['logfiles_path']}/access_log*|tail -n +7|xargs rm -r"
  mailto '/dev/null'
  action :create
end

cron 'logrotate' do
  minute '0'
  command 'sudo /usr/sbin/logrotate /etc/logrotate.d/tomcat'
  mailto '/dev/null'
  action :create
end

###############################################################################
# Setup Directories
###############################################################################
directory "#{node['tomcat']['webapp_install_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['webapp_install_dir']}"
end

link node['tomcat']['webapp_link'] do
  to node['tomcat']['webapp_install_dir']
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  not_if "test -d #{node['tomcat']['webapp_link']}"
end

directory "#{node['tomcat']['work_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['work_dir']}"
end

link node['tomcat']['work_link'] do
  to node['tomcat']['work_dir']
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  not_if "test -d #{node['tomcat']['work_link']}"
end

directory "#{node['tomcat']['scripts_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['scripts_dir']}"
end

directory "#{node['tomcat']['catalina_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['catalina_dir']}"
end

link node['tomcat']['catalina_link'] do
  to node['tomcat']['catalina_dir']
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  not_if "test -d #{node['tomcat']['catalina_link']}"
end

directory "#{node['tomcat']['context_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['context_dir']}"
end

link node['tomcat']['logfiles_path'] do
  to node['tomcat']['logfiles_path_dir']
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  not_if "test -d #{node['tomcat']['logfiles_path']}"
end

directory "#{node['tomcat']['keystore_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['keystore_dir']}"
end

link node['tomcat']['keystore_link'] do
  to node['tomcat']['keystore_dir']
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  not_if "test -d #{node['tomcat']['keystore_link']}"
end

directory "#{node['tomcat']['tmp_dir']}" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  recursive true
  not_if "test -d #{node['tomcat']['tmp_dir']}"
end

link node['tomcat']['tmp_link'] do
  to node['tomcat']['tmp_dir']
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  not_if "test -d #{node['tomcat']['tmp_link']}"
end

###############################################################################
#   Create Config Files From Templates
#   1 - server.xml
#   2 - context.xml
#   3 - tomcat-users.xml
#   4 - policy.d directory
#   6 - setenv.sh script
#   7 - tomcat.service
###############################################################################

template "#{node['tomcat']['instance_dir']}/conf/server.xml" do
  source 'server.xml.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0644'
end

template "#{node['tomcat']['instance_dir']}/conf/context.xml" do
  source 'context.xml.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0644'
end

template "#{node['tomcat']['instance_dir']}/conf/web.xml" do
  source 'web.xml.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0644'
end

template "#{node['tomcat']['instance_dir']}/conf/tomcat-users.xml" do
  source 'tomcat-users.xml.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0644'
end

directory "#{node['tomcat']['instance_dir']}/conf/policy.d" do
  action :create
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
end

template "#{node['tomcat']['instance_dir']}/bin/setenv.sh" do
  source 'setenv.sh.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0744'
end

template "#{node['tomcat']['scripts_dir']}/prestartup.sh" do
  source 'prestartup.sh.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0744'
  not_if {node['tomcat']['startup_shutdown']['pre_startup_command'].nil? || node['tomcat']['startup_shutdown']['pre_startup_command'].empty?}
end

template "#{node['tomcat']['scripts_dir']}/poststartup.sh" do
  source 'poststartup.sh.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0744'
  not_if {node['tomcat']['startup_shutdown']['post_startup_command'].nil? || node['tomcat']['startup_shutdown']['post_startup_command'].empty?}
end

template "#{node['tomcat']['scripts_dir']}/preshutdown.sh" do
  source 'preshutdown.sh.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0744'
  not_if {node['tomcat']['startup_shutdown']['pre_shutdown_command'].nil? || node['tomcat']['startup_shutdown']['pre_shutdown_command'].empty?}
end

template "#{node['tomcat']['scripts_dir']}/postshutdown.sh" do
  source 'postshutdown.sh.erb'
  owner "#{node['tomcat']['global']['tomcat_user']}"
  group "#{node['tomcat']['global']['tomcat_group']}"
  mode '0744'
  not_if {node['tomcat']['startup_shutdown']['post_shutdown_command'].nil? || node['tomcat']['startup_shutdown']['post_shutdown_command'].empty?}
end


template 'tomcat service' do
  path '/lib/systemd/system/tomcat.service'
  source 'init_systemd.erb'
  cookbook 'tomcat-2'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

service 'tomcat service enable' do
  provider Chef::Provider::Service::Systemd
  service_name 'tomcat'
  supports status: true
  action :enable
  only_if { ::File.exist?('/lib/systemd/system/tomcat.service') }
end

execute 'Load systemd unit file' do
  command 'systemctl daemon-reload'
  action :run
  only_if { ::File.exist?('/lib/systemd/system/tomcat.service') }
end

###############################################################################
# Nagios Scripts
###############################################################################

template '/opt/nagios/libexec/check_tomcat.rb' do
  source 'check_tomcat.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

template '/opt/nagios/libexec/check_ecv.rb' do
  source 'check_ecv.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end
###############################################################################
# Additional Recipes
#   These recipes will be called after the rest of the add.rb file is run.
###############################################################################

include_recipe 'tomcat-2::start'
