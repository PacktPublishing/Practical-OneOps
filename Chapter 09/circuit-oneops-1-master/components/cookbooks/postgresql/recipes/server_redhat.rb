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

include_recipe "postgresql::client"
cloud_var=node.workorder.payLoad.OO_CLOUD_VARS
repo_url=""
cloud_var.each do |var|
if var[:ciName] == "satproxy"
  repo_url = var[:ciAttributes][:value]
end
end
# Create a group and user like the package will.
# Otherwise the templates fail.

# hack for centos-6.0
Chef::Log.info("Checking if the postgres group already exists")
`grep -E "postgres" /etc/group`
if $?.to_i == 0
  Chef::Log.info("Group exists, skipping add")
else
  Chef::Log.info("postgres group missing, adding postgres group") 
  `groupadd postgres -g 26 ; true`
  
  group "postgres" do
    # Workaround lack of option for -r and -o...
    group_name "-r -o postgres"
    not_if { Etc.getgrnam("postgres") }
    gid 26
  end
end

Chef::Log.info("Checking if the postgres user already exists")
    `grep -E "postgres" /etc/passwd`
if $?.to_i == 0
    Chef::Log.info("User exists, skipping add")
else
    Chef::Log.info("postgres user missing, adding postgres user") 
    `useradd postgres -g postgres -u 26 -r -d /var/lib/pgsql -m -s /bin/bash ; true`
    
    user "postgres" do
      # Workaround lack of option for -M and -n...
      username "-M -n postgres"
      not_if { Etc.getpwnam("postgres") }
      shell "/bin/bash"
      comment "PostgreSQL Server"
      home "/var/lib/pgsql"
      gid "postgres"
      system true
      uid 26
      supports :non_unique => true
    end
end

postgresql_conf = JSON.parse(node.postgresql.postgresql_conf)
data_dir = ""
if postgresql_conf.has_key?('data_directory')
  data_dir = postgresql_conf['data_directory'].gsub(/\A'(.*)'\z/m,'\1')
else
  data_dir = "#{node[:postgresql][:data]}"
end
Chef::Log.info("data_dir: "+data_dir)

directory data_dir do
  owner "postgres"
  group "postgres"
  recursive true
  mode 0700
end
flat_version = node.postgresql.version.split('.').join
# try to add public repo - but os.repo_list could already have this setup for internal repo - ok if fails/exit code 1
execute "rpm -ivh http://yum.postgresql.org/#{node.postgresql.version}/redhat/rhel-7-x86_64/pgdg-centos#{flat_version}-#{node.postgresql.version}-3.noarch.rpm" do
  returns [0,1]
end

package "postgresql" do
  case node.platform
  when "redhat","centos"
    package_name "postgresql#{node.postgresql.version.split('.').join}"
  else
    package_name "postgresql"
  end
end

case node.platform
when "redhat","centos"
  package "postgresql#{node.postgresql.version.split('.').join}-server"
  package "postgresql#{node.postgresql.version.split('.').join}-contrib"
  package "postgresql#{node.postgresql.version.split('.').join}-devel"
  package "postgresql#{node.postgresql.version.split('.').join}-libs"
when "fedora","suse"
  package "postgresql-server"
  package "postgresql-contrib"
  package "postgresql-devel"
  package "postgresql-libs"
end

# only stop the inital start by yum install/add
if node.workorder.rfcCi.rfcAction == "add"
  if node.postgresql.version.to_f >= 9
    service "postgresql-#{node.postgresql.version}" do
      supports :restart => true, :status => true, :reload => true
      action [:enable, :stop]
    end
  else
    service "postgresql" do
      supports :restart => true, :status => true, :reload => true
      action [:enable, :stop]
    end  
  end
end
