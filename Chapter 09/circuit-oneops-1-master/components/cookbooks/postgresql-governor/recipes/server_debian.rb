#/postgresql.conf.
# Cookbook Name:: postgresql
# Recipe:: server
#
# Copyright 2009-2010, Opscode, Inc.
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

# include_recipe "postgresql::client"

if node[:postgresql][:version].to_f >= 9.0 && node.platform == "ubuntu" && node.platform_version.to_f < 11.10
  ruby_block 'Add PPA repository' do
    block do
      `add-apt-repository ppa:pitti/postgresql`
      `apt-get -y update`
    end
  end
end

ruby_block 'Check for dpkg lock' do
  block do
    sleep rand(15)
    retry_count = 0
    while system('lsof /var/lib/dpkg/lock') && retry_count < 20
      Chef::Log.warn("Found lock. Will retry package #{name} in #{node.workorder.rfcCi.ciName}")
      sleep rand(5)+10
      retry_count += 1
    end   
  end
end

    
package "postgresql-#{node[:postgresql][:version]}"
package "postgresql-contrib-#{node[:postgresql][:version]}"

service "postgresql" do
  service_name "postgresql"
  pattern "postgres: writer"
  supports :stop => true, :start => true, :restart => true, :reload => true
  action [:enable, :stop]
end