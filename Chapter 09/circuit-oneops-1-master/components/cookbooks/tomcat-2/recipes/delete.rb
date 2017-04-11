###############################################################################
# Cookbook Name:: tomcat-2
# Recipe:: delete
# Purpose:: This recipe is used to delete the Tomcat system by disabling the
#           service and deleting the directory
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

node.set['tomcat']['config_dir'] = '/opt/tomcat'

service "tomcat" do
  only_if { ::File.exists?('/lib/systemd/system/tomcat.service') }
  service_name "tomcat"
  action [:stop, :disable]
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

directory "#{node['tomcat']['config_dir']}" do
   recursive true
   action :delete
end
