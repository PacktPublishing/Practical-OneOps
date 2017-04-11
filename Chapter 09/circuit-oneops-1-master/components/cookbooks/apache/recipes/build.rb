# Copyright 2016, Walmart Stores, Inc.
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

node.set[:apache][:build_options] = Mash.new(JSON.parse(node.workorder.rfcCi.ciAttributes.build_options))
node.set[:apache][:dir] = node[:apache][:build_options][:prefix]
node.set[:apache][:log_dir] = "#{node[:apache][:dir]}/logs"
node.set[:apache][:binary] = "#{node[:apache][:dir]}/bin/httpd"
node.set[:apache][:icondir] = "#{node[:apache][:dir]}/icons"
if node.workorder.rfcCi.ciAttributes.user.empty?
  node.set[:apache][:user] = 'nobody'
  case node[:platform]
  when "centos","redhat","fedora","suse"
    node.set[:apache][:group] = 'nobody'
  when "debian","ubuntu"  
      node.set[:apache][:group] = 'nogroup'
  end
else
  node.set[:apache][:user] = node.workorder.rfcCi.ciAttributes.user
end

Chef::Log.debug("Build options: #{node[:apache][:build_options].inspect}")

# pre-requisite libraries
case node[:platform]
when "centos","redhat","fedora","suse"
  package_list = ["kernel-devel","gcc-c++","pcre-devel","openssl-devel","libcurl-devel","libicu-devel","libmcrypt","libmcrypt-devel","libtool-ltdl-devel"]
when "debian","ubuntu"
  package_list = ["build-essential","libpcre3-dev","libexpat-dev","libssl-dev","libcurl4-openssl-dev","libicu-dev","mcrypt","libmcrypt-dev","libltdl-dev"]
end

package_list.each do |name|
  package "#{name}"
end

# lynx is used in the apachectl status
package "lynx"

if node.workorder.rfcCi.rfcAction == "add" || (node.workorder.rfcCi.rfcAction == "update" && node.workorder.rfcCi.ciBaseAttributes.has_key?("build_options"))
  directory "#{node[:apache][:build_options][:srcdir]}" do
    recursive true
    mode 0775
    action :create
  end
  
  # get apache from source
  git "#{node[:apache][:build_options][:srcdir]}" do
    depth 1
    enable_submodules false
    repository "git://github.com/apache/httpd.git"
    revision "#{node[:apache][:build_options][:version]}"
    action :sync
  end

  Chef::Log.debug("./configure --with-pcre --prefix=#{node[:apache][:build_options][:prefix]} #{node[:apache][:build_options][:configure]}")
  script "configure_apache" do
    interpreter "bash"
    user 'root'
    group 'root'
    cwd "#{node[:apache][:build_options][:srcdir]}"
    code <<-EOS
    svn co -q http://svn.apache.org/repos/asf/apr/apr/branches/1.4.x srclib/apr
    svn co -q http://svn.apache.org/repos/asf/apr/apr-util/branches/1.3.x srclib/apr-util
    mv configure.in configure.ac
    ./buildconf
    ./configure --quiet --with-pcre --prefix=#{node[:apache][:build_options][:prefix]} #{node[:apache][:build_options][:configure]}
    EOS
  end
   
  script "build_apache" do
    interpreter "bash"
    user 'root'
    group 'root'
    cwd "#{node[:apache][:build_options][:srcdir]}"
    code <<-EOS
    make --quiet clean
    make --quiet
    EOS
  end
  
  script "install_apache" do
    interpreter "bash"
    user 'root'
    group 'root'
    cwd "#{node[:apache][:build_options][:srcdir]}"
    code <<-EOS
    make --quiet install
    EOS
  end
else
  Chef::Log.info("Update called without new build options, skipping apache build")
end


# configure

cookbook_file "#{node[:apache][:dir]}/bin/module_conf_generate.pl" do
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
  command "#{node[:apache][:dir]}/bin/module_conf_generate.pl #{node[:apache][:dir]}/modules #{node[:apache][:dir]}/mods-available"
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

template "httpd.conf" do
  path "#{node[:apache][:dir]}/conf/httpd.conf"
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

# modules
node[:apache][:modules].each do |m|
  Chef::Log.info("Enabling module #{m}")
  include_recipe "apache::#{m.strip}"
end

# need to add logic for a2dismod from ciBaseAttributes


case node[:platform]
when "centos","redhat","fedora","suse"
  template "/etc/init.d/httpd" do
    source "httpd.init.erb"
    owner "root"
    group "root"
    mode 0755
    backup false
  end
  node[:apache][:service] = 'httpd'
when "debian","ubuntu"
  link "/etc/init.d/apache2" do
    to "#{node[:apache][:dir]}/bin/apachectl"
  end
  node[:apache][:service] = 'apache2'
end

service "apache2" do
  service_name node[:apache][:service]
  pattern "#{node[:apache][:dir]}/bin/httpd"
  supports :restart => true
  action [ :enable, :restart ]
end
