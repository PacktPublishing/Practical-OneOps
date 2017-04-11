#
# Cookbook Name:: apache2
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
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
#

node.set[:apache][:user] = node.workorder.rfcCi.ciAttributes.user unless node.workorder.rfcCi.ciAttributes.user.empty?

package "apache2" do
  case node[:platform]
  when "centos","redhat","fedora","suse"
    package_name "httpd"
  when "debian","ubuntu"
    package_name "apache2"
  when "arch"
    package_name "apache"
  end
  action :install
end

# additional dev packages
pkgs = value_for_platform(
  [ "centos", "redhat", "fedora" ] => {
    "default" => %w{ pcre-devel }
  },
  [ "debian", "ubuntu" ] => {
    "default" => %w{ libcurl4-openssl-dev libssl-dev zlib1g-dev apache2-prefork-dev libapr1-dev libaprutil1-dev }
  },
  "default" => %w{ libcurl4-openssl-dev libssl-dev zlib1g-dev apache2-prefork-dev libapr1-dev libaprutil1-dev }
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

if node.platform == "ubuntu"
  execute "mkdir -p /etc/apache2/conf.modules.d/"
end


service "apache2" do
  case node[:platform]
  when "centos","redhat","fedora","suse"
    service_name "httpd"
    # If restarted/reloaded too quickly httpd has a habit of failing.
    # This may happen with multiple recipes notifying apache to restart - like
    # during the initial bootstrap.
    restart_command "/sbin/service httpd restart && sleep 1"
    reload_command "/sbin/service httpd reload && sleep 1"
  when "debian","ubuntu"
    service_name "apache2"
    restart_command "/usr/sbin/invoke-rc.d apache2 restart && sleep 1"
    reload_command "/usr/sbin/invoke-rc.d apache2 reload && sleep 1"
  when "arch"
    service_name "httpd"
  end
  supports value_for_platform(
    "debian" => { "4.0" => [ :restart, :reload ], "default" => [ :restart, :reload, :status ] },
    "ubuntu" => { "default" => [ :restart, :reload, :status ] },
    "centos" => { "default" => [ :restart, :reload, :status ] },
    "redhat" => { "default" => [ :restart, :reload, :status ] },
    "fedora" => { "default" => [ :restart, :reload, :status ] },
    "arch" => { "default" => [ :restart, :reload, :status ] },
    "default" => { "default" => [:restart, :reload ] }
  )
  action :enable
end

if platform?("centos", "redhat", "fedora", "suse", "arch")
  directory node[:apache][:log_dir] do
    mode 0755
    action :create
  end

  cookbook_file "/usr/local/bin/module_conf_generate.pl" do
    source "module_conf_generate.pl"
    mode 0755
    owner "root"
    group "root"
  end

  %w{sites-available sites-enabled mods-available mods-enabled}.each do |dir|
    directory "#{node[:apache][:dir]}/#{dir}" do
      mode 0755
      owner "root"
      group "root"
      action :create
    end
  end

  execute "generate-module-list" do
    if node[:kernel][:machine] == "x86_64"
      libdir = value_for_platform("arch" => { "default" => "lib" }, "default" => "lib64")
    else
      libdir = "lib"
    end
    command "/usr/local/bin/module_conf_generate.pl /usr/#{libdir}/httpd/modules /etc/httpd/mods-available"
    action :run
  end

  %w{a2ensite a2dissite a2enmod a2dismod}.each do |modscript|
    template "/usr/sbin/#{modscript}" do
      source "#{modscript}.erb"
      mode 0755
      owner "root"
      group "root"
    end
  end

  # installed by default on centos/rhel, remove in favour of mods-enabled
  file "#{node[:apache][:dir]}/conf.d/proxy_ajp.conf" do
    action :delete
    backup false
  end
  file "#{node[:apache][:dir]}/conf.d/README" do
    action :delete
    backup false
  end

  file "#{node[:apache][:dir]}/conf.d/nagios.conf" do
    action :delete
    backup false
  end

  # welcome page moved to the default-site.rb temlate
  file "#{node[:apache][:dir]}/conf.d/welcome.conf" do
    action :delete
    backup false
  end
end

if ["redhat","centos"].include?(node.platform)

  pkgs = ["openssl-devel","curl-devel", "httpd-devel", "apr-util-devel", "apr-devel","gcc-c++","zlib-devel"]
  pkgs.each do |pkg|
    package pkg do
      action :install
    end
  end

  # remove bad nagios ui config that redhat installs
  execute "rm -f /etc/httpd/conf.d/nagios.conf"

end

directory "#{node[:apache][:dir]}/ssl" do
  action :create
  mode 0755
  owner "root"
  group "root"
end

directory "#{node[:apache][:dir]}/conf.d" do
  action :create
  mode 0755
  owner "root"
  group "root"
end

directory node[:apache][:cache_dir] do
  action :create
  mode 0755
  owner node[:apache][:user]
end

template "apache2.conf" do
  case node[:platform]
  when "centos","redhat","fedora","arch"
    path "#{node[:apache][:dir]}/conf/httpd.conf"
  when "debian","ubuntu"
    path "#{node[:apache][:dir]}/apache2.conf"
  end
  source "httpd.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables :ports => node[:apache][:listen_ports]
end

template "security" do
  path "#{node[:apache][:dir]}/conf.d/security"
  source "security.erb"
  owner "root"
  group "root"
  mode 0644
  backup false
end

template "charset" do
  path "#{node[:apache][:dir]}/conf.d/charset"
  source "charset.erb"
  owner "root"
  group "root"
  mode 0644
  backup false
end

template "other-vhosts-access-log" do
  path "#{node[:apache][:dir]}/conf.d/other-vhosts-access-log"
  source "other-vhosts-access-log.erb"
  owner "root"
  group "root"
  mode 0644
  backup false
  notifies :restart, resources(:service => "apache2")
end

# modules
node[:apache][:modules].each do |m|
  Chef::Log.info("Enabling module #{m}")
  include_recipe "apache::#{m}"
end

include_recipe "apache::mod_log_config" if platform?("centos", "redhat", "fedora", "suse", "arch")

file "/var/www/index.php" do
  content node[:apache][:php_index_content]
  mode 0644
end

apache_site "default" do
  enable false
end

service "apache2" do
  case node[:platform]
  when "centos","redhat","fedora","suse"
    service_name "httpd"
    # If restarted/reloaded too quickly httpd has a habit of failing.
    # This may happen with multiple recipes notifying apache to restart - like
    # during the initial bootstrap.
    restart_command "/sbin/service httpd restart && sleep 1"
    reload_command "/sbin/service httpd reload && sleep 1"
  when "debian","ubuntu"
    service_name "apache2"
    restart_command "/usr/sbin/invoke-rc.d apache2 restart && sleep 1"
    reload_command "/usr/sbin/invoke-rc.d apache2 reload && sleep 1"
  when "arch"
    service_name "httpd"
  end
  action :start
end
