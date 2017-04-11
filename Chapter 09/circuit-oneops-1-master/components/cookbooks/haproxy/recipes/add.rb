#
# Cookbook Name:: haproxy
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

package "haproxy" do
  action :install
end

case node.platform
when "redhat","centos","fedora","suse"
  _addl_packages = ['libxslt-devel','libxml2-devel','socat']
when "debian","ubuntu"
  _addl_packages = ['libxslt-dev','libxml2-dev']
end

_addl_packages.each do |pkg|
  package "#{pkg}" do
    action :install
  end
end

if node.haproxy.has_key?("override_config") && !node.haproxy.override_config.empty?
  file "/etc/haproxy/haproxy.cfg" do
    content node.haproxy.override_config
  end
else
  template "/etc/haproxy/haproxy.cfg" do
    source "haproxy.cfg.erb"
    owner "root"
    group "root"
    mode 0644
    notifies :restart, "service[haproxy]"
  end
end

template "/opt/nagios/libexec/check_haproxy.rb" do
  source "check_haproxy.rb.erb"
  owner "root"
  group "root"
  mode 0755
end

service "haproxy" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :restart]
end
