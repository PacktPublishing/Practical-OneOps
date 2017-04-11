#
# Cookbook Name:: nginx
# Recipe:: default
# Author:: AJ Christensen <aj@junglist.gen.nz>
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

node.set[:nginx][:events] = Mash.new(JSON.parse(node.workorder.rfcCi.ciAttributes.events))

package "nginx"
pkgs = value_for_platform(
    ["debian","ubuntu"] => { "default" => ["nginx"] },
                             "default" => ["nginx"]
)
# I don't know why should we install php packages by default so I removed them:
# "php", "php-fpm", "wget", "php-common","php-pear", "php-pdo", "php-mysql", "php-pgsql", "php-pecl-apc", 
# "php-gd", "php-mbstring", "php-mcrypt", "php-xml" 

pkgs.each do |pkg|
    package pkg do
        action :install
    end
end

`mkdir -p #{node[:nginx][:dir]}/sites-available/ #{node[:nginx][:dir]}/sites-enabled #{node[:nginx][:dir]}/sites-disabled`

directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:nginx][:user]
  action :create
end

%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    source "#{nxscript}.erb"
    mode 0755
    owner "root"
    group "root"
  end
end

template "nginx.conf" do
  path "#{node[:nginx][:dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

directory "/opt/nagios/libexec/" do
  recursive true
end

template "check_nginx.rb" do
  path "/opt/nagios/libexec/check_nginx.rb"
  source "check_nginx.rb.erb"
  owner "root"
  group "root"
  mode 0755
end

# create a default site, but don't enable it
template "#{node[:nginx][:dir]}/sites-available/default" do
  source "default-site.erb"
  owner "root"
  group "root"
  mode 0644
end

link "#{node[:nginx][:dir]}/sites-enabled/default" do
  action :delete
  only_if "test -L #{node[:nginx][:dir]}/sites-enabled/default"
end

# this should be configurable attribute
service "nginx" do
  action [ :stop, :disable ]
end


ruby_block "fedora hack" do
  block do
    if node.platform == "fedora"
      `wget -O init-rpm.sh http://library.linode.com/assets/635-init-rpm.sh`
      `mv init-rpm.sh /etc/rc.d/init.d/nginx`
      `chmod +x /etc/rc.d/init.d/nginx`
    end
  end
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end


