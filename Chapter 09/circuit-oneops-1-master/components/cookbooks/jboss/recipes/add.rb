#
# Cookbook Name:: jboss
# Default:: default
#
# Copyright 2010, Opscode, Inc.
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

jboss_version = node.workorder.rfcCi.ciAttributes.version
short_jboss_version = jboss_version.gsub(/\.\d+$/,'')

dl_url = node.workorder.rfcCi.ciAttributes["jboss_url_enabled"] ? node.workorder.rfcCi.ciAttributes["jboss_url"] : "http://download.jboss.org/jbossas/#{short_jboss_version}/jboss-as-#{jboss_version}.Final/jboss-as-#{jboss_version}.Final.tar.gz"

base_name = "jboss-as-#{jboss_version}.Final"

jboss_home = node['jboss']['jboss_home']
jboss_user = node['jboss']['jboss_user']

user jboss_user do
  system true
  shell '/bin/false'
  action :create
  only_if { jboss_user == "jboss" }
end
package 'wget'
# get files
bash "put_files" do
  code <<-EOH
  cd /tmp
  wget #{dl_url}
  cd /opt
  if [ -f /tmp/jboss-#{jboss_version}.tar.gz ]; then
    mv /tmp/jboss-#{jboss_version}.tar.gz /tmp/#{base_name}.tar.gz
    elif [ -f /tmp/#{base_name}-#{jboss_version}.tar.gz ]; then
    mv /tmp/#{base_name}-#{jboss_version}.tar.gz /tmp/#{base_name}.tar.gz
  fi  
  tar -zxf /tmp/#{base_name}.tar.gz
  ln -s /opt/#{base_name} #{jboss_home}
  rm -f /tmp/#{base_name}.tar.gz
  chown -R #{jboss_user}:#{jboss_user} /opt/#{base_name}
  EOH
  not_if "test -d #{jboss_home}"
end

template "#{jboss_home}/standalone/configuration/standalone.xml" do
  source 'standalone.xml.erb'
  owner jboss_user
end

# template init file
template "/etc/init.d/jboss" do
  if platform? ["centos", "redhat"] 
    source "init_el.erb"
  else
    source "init_deb.erb"
  end
  mode "0755"
  owner "root"
  group "root"
end

# start service
service "jboss" do
  action [ :enable, :start ]
end
