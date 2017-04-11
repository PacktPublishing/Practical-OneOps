# Cookbook Name:: postgresql-governor
# Recipe:: add
#
# Author : OneOps
# Apache License, Version 2.0

include_recipe "postgresql-governor::set_domain_name"

# Install `etcd` gem for chef-client use
Chef::Log.info("install etcd gem")
chef_gem 'etcd' do
    action :install
end

postgresql_conf = JSON.parse(node['postgresql-governor']['postgresql_conf'])
data_dir = ""
if postgresql_conf.has_key?('data_directory')
    data_dir = postgresql_conf['data_directory'].gsub(/\A'(.*)'\z/m,'\1')
    else
    data_dir = "#{node['postgresql-governor'][:data]}"
end

Chef::Log.info("data_dir = " + data_dir)

%w{patch python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end

# Include the right "family" recipe for installing the server
# since they do things slightly differently.
case node.platform
    when "redhat", "centos", "fedora", "suse"
    if node['postgresql-governor']['version'].to_f >= 9
        # rhel puts them in same dir
        node.set['postgresql-governor']['dir'] = data_dir
        node.set['postgresql-governor']['data'] = data_dir
    end
    
    include_recipe "postgresql-governor::server_redhat"
    when "debian", "ubuntu"
    include_recipe "postgresql-governor::server_debian"
end

execute "chown-data-dir" do
    command "chown -R postgres:postgres #{node['postgresql-governor']['data']}"
    user "root"
    action :run
end

execute "chmod-700-data-dir" do
    command "chmod -R 700 #{node['postgresql-governor']['data']}"
    user "root"
    action :run
end



require 'rubygems'
require 'etcd'
client = Etcd.client(host: 'localhost', port: 2379)
ciName = node.workorder.payLoad.ManagedVia[0]['ciName'].split("-").join

if node.workorder.cloud.ciAttributes.has_key?("priority") &&
    node.workorder.cloud.ciAttributes.priority.to_i == 1
  Chef::Log.info("In primary clouds")
  
  fqdn_resolv = `host #{node[:platform_fqdn]} | awk '{ print $NF }'`.split("\n")
  Chef::Log.info("fqdn_resolv: #{fqdn_resolv.to_s}")
  while true
    if fqdn_resolv[0] =~ /NXDOMAIN/
      Chef::Log.info("Unable to resolve platform-level FQDN, sleep 5s and retry: #{node[:platform_fqdn]}")
      sleep(5)
      fqdn_resolv = `host #{node[:platform_fqdn]} | awk '{ print $NF }'`.split("\n")
    else
      break;
    end
  end

  client.set('/service/postgres/primary_cloud/' + ciName, value: ciName)
else
  Chef::Log.info("In secondary clouds")
  
  # just want to set some value for key `/service/postgres/initialize` to avoid unclean leader takeover
  # the value of `/service/postgres/initialize/` is not important
  client.set('/service/postgres/initialize', value: ciName)

end

# start to install and config governor
remote_file "/tmp/governer.zip" do
    owner 'root'
    group 'root'
    mode 0755
    source node['postgresql-governor'][:governor_download]
end

directory node['postgresql-governor'][:governor_home] do
    recursive true
    owner 'postgres'
    group 'postgres'
    action :delete
end

# unzip the package
bash "unzip governer.zip" do
    user 'postgres'
    group 'postgres'
    code "unzip /tmp/governer.zip -d /var/lib/pgsql/"
    returns 0
end

# download the patch file for "helpers/ha.py" for supporting OneOps primary, secondary clouds
cookbook_file "#{node['postgresql-governor']['governor_home']}/ha.py.patch" do
    source 'ha.py.patch'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
end

# patch "helpers/ha.py"
execute "patch ha.py" do
    user "root"
    cwd node['postgresql-governor']['governor_home']
    command "patch helpers/ha.py < ha.py.patch"
    only_if 'patch -p1 -N --dry-run --silent #{node[:governor_home]}/helpers/ha.py < #{node[:governor_home]}/ha.py.patch'
end


template "#{node['postgresql-governor']['governor_home']}/postgres.yml" do
    source "postgres.yml.erb"
    owner "postgres"
    group "postgres"
    mode 0644
end

# writing governor systemd file
template node['postgresql-governor']['governor_systemd_file'] do
    source 'governor.service.erb'
    mode 0644
end

# enable and restart governor service
service 'governor' do
    action [:enable, :restart]
end


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

# TODO: check if postgresql-dev still needs to be separately installed
dev_package = "postgresql-server-dev-all"
if node.platform != "ubuntu"
    dev_package = "postgresql-server-devel"
    if node['postgresql-governor']['version'].to_f >= 9
        dev_package = "postgresql#{node['postgresql-governor']['version'].split('.').join}-devel"
    end
end

package dev_package do
    action :install
end

#Install the gem pg
execute "sudo /usr/bin/gem install pg -v 0.17.1 --no-rdoc --no-ri -- --with-pg-config=/usr/pgsql-#{node['postgresql-governor'][:version]}/bin/pg_config"

template '/opt/nagios/libexec/check_sql_pg.rb' do
    source "check_sql_pg.erb"
    owner "oneops"
    group "oneops"
    mode 0755
end

template '/etc/nagios3/pg_stats.yaml' do
    source "pg_stats.yaml.erb"
    mode 0644
end

template '/opt/nagios/libexec/check_replicators.sh' do
    source 'check_replicators.sh.erb'
    mode 0755
    owner 'oneops'
    group 'oneops'
end

template '/opt/nagios/libexec/check_backups.sh' do
    source 'check_backups.sh.erb'
    mode 0755
    owner 'oneops'
    group 'oneops'
end

# writing haproxy_status systemd file
template node['postgresql-governor']['haproxy_status_systemd_file'] do
    source 'haproxy_status.service.erb'
    mode 0644
end

# enable and restart haproxy_status service
service 'haproxy_status' do
    action [:enable, :restart]
end
