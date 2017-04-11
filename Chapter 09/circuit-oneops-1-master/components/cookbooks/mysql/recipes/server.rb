#
# Cookbook Name:: mysql
# Recipe:: default
#
# Copyright 2008-2011, Opscode, Inc.
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

require "net/http"
case node.platform_family 
  
when "rhel"
  package "yum-utils"
  cloud_name = node[:workorder][:cloud][:ciName]

  if node[:workorder][:services].has_key? "mirror"
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  else
    msg = "Cloud Mirror Service has not been defined"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL= #{msg}"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end

  mysql_source = mirrors['mysql']

  if mysql_source.nil?
    mysql_source = "http://repo.mysql.com/yum"
    Chef::Log.info("mysql source repository has not been defined in cloud mirror service so defining default location #{mysql_source}")
  else
    Chef::Log.info("mysql source repository has been defined in cloud mirror service #{mysql_source}")
  end

  case
  when node[:platform_version].start_with?("5")
    repo = "#{mysql_source}/mysql-#{node.mysql.version}-community/el/5/x86_64/"
  when node[:platform_version].start_with?("6")
    repo = "#{mysql_source}/mysql-#{node.mysql.version}-community/el/6/x86_64/"
  when node[:platform_version].start_with?("7")
    repo = "#{mysql_source}/mysql-#{node.mysql.version}-community/el/7/x86_64/"
  end

  url = URI.parse(repo)
  req = Net::HTTP.new(url.host, url.port)
  res = req.request_head(url.path)

  if res.code != "200"
    msg = "#{repo} is not a valid url. HTTP Response Code is #{res.code}"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL= #{msg}"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end

  Chef::Log.info("mysql repository is #{repo}")
  repo_file = "/etc/yum.repos.d/" +repo.gsub("http://","").gsub("https://","").gsub("/","_") + ".repo"
  execute "yum-config-manager --add-repo #{repo} ; echo gpgcheck=0 >> #{repo_file}"
end

include_recipe "mysql::client"

# generate all passwords
# node.set_unless['mysql']['server_debian_password'] = secure_password
# node.set_unless['mysql']['server_root_password']   = secure_password
# node.set_unless['mysql']['server_repl_password']   = secure_password

node.set_unless['mysql']['server_debian_password'] = node.workorder.rfcCi.ciAttributes.password
node.set_unless['mysql']['server_root_password']   = node.workorder.rfcCi.ciAttributes.password
node.set_unless['mysql']['server_repl_password']   = node.workorder.rfcCi.ciAttributes.password

node.set_unless['mysql']['password']   = node.workorder.rfcCi.ciAttributes.password

is_cluster = false
is_slave = false
mount_point = ""

# increase shmmax and shmall for databases
page_size=(`getconf PAGE_SIZE`).to_i
phys_pages=(`getconf _PHYS_PAGES`).to_i
shmall=phys_pages / 2
shmmax=shmall * page_size
`grep shmmax /etc/sysctl.conf`
if $?.to_i != 0
  Chef::Log.info( "#Maximum shared segment size in bytes")
  `echo "#Maximum shared segment size in bytes" >> /etc/sysctl.conf`
  Chef::Log.info( "kernel.shmmax = #{shmmax}")
  `echo "kernel.shmmax = #{shmmax}" >> /etc/sysctl.conf`
  Chef::Log.info( "#Maximum number of shared memory segments in pages")
  `echo  "#Maximum number of shared memory segments in pages" >> /etc/sysctl.conf`
  Chef::Log.info( "kernel.shmall = #{shmall}")
  `echo "kernel.shmall = #{shmall}" >> /etc/sysctl.conf`
  `/sbin/sysctl -p`
else
  Chef::Log.info( "sysctl shmax already set in /etc/sysctl.conf")
end




if platform?(%w{debian ubuntu})

  directory "/var/cache/local/preseeding" do
    owner "root"
    group "root"
    mode 0755
    recursive true
  end

  execute "preseed mysql-server" do
    command "debconf-set-selections /var/cache/local/preseeding/mysql-server.seed"
    action :nothing
  end

  template "/var/cache/local/preseeding/mysql-server.seed" do
    source "mysql-server.seed.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :run, resources(:execute => "preseed mysql-server"), :immediately
  end

  template "#{node['mysql']['conf_dir']}/debian.cnf" do
    source "debian.cnf.erb"
    owner "root"
    group "root"
    mode "0600"
  end

end

package "mysql-server" do
  action :install
end

service "mysql" do
  service_name value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")
  if (platform?("ubuntu") && node.platform_version.to_f >= 10.04)
    restart_command "restart mysql"
    stop_command "stop mysql"
    start_command "start mysql"
  end
  supports :status => true, :restart => true, :stop => true, :reload => true
  action :nothing
  not_if { is_slave }
end

ruby_block "use datadir attribute" do
  block do
    
    depends_set = node.workorder.payLoad.DependsOn
    
    depends_set.each do |depends_on|
      depends_on_type = depends_on["ciClassName"]
      depends_on_index = (depends_on["ciName"][-1,1]).to_i
      if depends_on_type =~ /Volume/
        mount_point = depends_on["ciAttributes"]["mount_point"]
        if depends_on_index > 1
          is_slave = true
          Chef::Log.info("instance is NOT primary")
        else
          Chef::Log.info("instance is primary")    
        end
      end
    end
    

    data_dir = node.mysql.datadir    
    if !data_dir.empty?
      if ::File.exists?(node['mysql']['data_dir']+"/mysql")
        `chown -R mysql:mysql #{data_dir}`
        
        Chef::Log.info("teardown and remove apparmor")            
        `service apparmor teardown`
        `apt-get -y remove apparmor`
      end
      Chef::Log.info("setting node['mysql']['data_dir'] = "+data_dir)            
      node.set['mysql']['data_dir'] = data_dir      
    end
          
  end
end


template "#{node['mysql']['conf_dir']}/my.cnf" do
  source "my.cnf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "mysql"), :immediately
end


# set the root password on platforms 
# that don't support pre-seeding
# 11.10+ ubuntu looks to need this
#unless platform?(%w{debian ubuntu})
unless platform?(%w{debian})
  execute "assign-root-password" do
    command "/usr/bin/mysqladmin -u root password \"#{node['mysql']['server_root_password']}\""
    action :run
    only_if "/usr/bin/mysql -u root -e 'show databases;'"
  end
end

grants_path = "#{node['mysql']['conf_dir']}/mysql_grants.sql"

begin
  t = resources("template[#{grants_path}]")
rescue
  Chef::Log.info("Could not find previously defined grants.sql resource")
  t = template grants_path do
    source "grants.sql.erb"
    owner "root"
    group "root"
    mode "0600"
    action :create
  end
end

execute "mysql-install-privileges" do
  command "/usr/bin/mysql -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }'#{node['mysql']['server_root_password']}' < #{grants_path}"
  only_if { is_slave == false }
end
#  action :nothing
#  subscribes :run, resources("template[#{grants_path}]"), :immediately


template "/opt/nagios/libexec/check_mysql.rb" do
  source "check_mysql.rb.erb"
  owner "oneops"
  group "oneops"
  mode "0755"
end
#  not_if { ::File.exists?("#{node['mysql']['conf_dir']}/my.cnf") }

ruby_block "old libssl" do
  block do
    # some ubuntu versions havent updated to 10 yet - needed for the nagios check_mysql
    if ! ::File.exists?("/lib/libssl.so.10") && node.platform =="ubuntu"
      if node.platform_version.to_i >= 12
        `ln -fs /usr/lib/x86_64-linux-gnu/libmysqlclient.so.18 /usr/lib/x86_64-linux-gnu/libmysqlclient.so.16`
        `ln -fs /lib/x86_64-linux-gnu/libssl.so.1.0.0 /lib/libssl.so.10`
        `ln -fs /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so.10`       
      else
        `ln -fs /lib/libssl.so.0.9.8 /lib/libssl.so.10`
        `ln -fs /lib/libcrypto.so.0.9.8 /lib/libcrypto.so.10`              
      end
    end
    
    # 12.04
    
    
  end
end

ruby_block "enable auto start" do
  block do
  begin
  `sudo -s chkconfig mysqld on`
   Chef::Log.info("enable auto start: chkconfig")
  rescue => error
      Chef::Log.info("can not enable auto start : #{error.message}")
  end
  end
end
