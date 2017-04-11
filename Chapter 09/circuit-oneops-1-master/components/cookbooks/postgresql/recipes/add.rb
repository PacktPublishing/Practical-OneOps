#
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

#version = node.workorder.rfcCi.ciAttributes[:version]
node.default[:postgresql][:version] = node.workorder.rfcCi.ciAttributes[:version]
node.default[:postgresql][:ssl] = "false"

pg_bin = "/usr/lib/postgresql/#{node[:postgresql][:version]}/bin"
case node.platform
when "redhat","centos"
  pg_bin = "/usr/pgsql-#{node[:postgresql][:version]}/bin"
end

postgresql_conf = JSON.parse(node.postgresql.postgresql_conf)
data_dir = ""
if postgresql_conf.has_key?('data_directory')
  data_dir = postgresql_conf['data_directory'].gsub(/\A'(.*)'\z/m,'\1')
else
  data_dir = "#{node[:postgresql][:data]}"
end



# Include the right "family" recipe for installing the server
# since they do things slightly differently.
case node.platform
when "redhat", "centos", "fedora", "suse"
  if node.postgresql.version.to_f >= 9  
    # rhel puts them in same dir
    node.set[:postgresql][:dir] = data_dir
    node.set[:postgresql][:data] = data_dir
  end

  include_recipe "postgresql::server_redhat"
when "debian", "ubuntu"
  include_recipe "postgresql::server_debian"
end

depends_set = node.workorder.payLoad.DependsOn
# standby by means of moving ebs or other blockstorage volumes
is_standby_using_volume = false

# standby via postgresql replication 
is_hot_standby = false

master_payload = nil

# install the gem pg
execute "sudo /usr/bin/gem install pg -v 0.17.1 --no-rdoc --no-ri -- --with-pg-config=/usr/pgsql-#{node[:postgresql][:version]}/bin/pg_config"


# standby instances will have a master payload 
# redundant needs a different payload due to lb
master = nil
if node.workorder.payLoad.has_key?("master") &&
  node.workorder.payLoad[:master][0][:ciClassName] =~ /Compute/
  master = node.workorder.payLoad[:master][0]
elsif node.workorder.payLoad.has_key?("master_redundant") &&
  node.workorder.payLoad[:master_redundant][0][:ciClassName] =~ /Compute/
  master = node.workorder.payLoad[:master_redundant][0]
end



if master.nil?
  
  # only init if no PG_VERSION file
  Chef::Log.info("checking for #{node.postgresql.dir}/PG_VERSION")
  unless ::FileTest.exist?(File.join(node.postgresql.dir, "PG_VERSION"))
    initdb = "/sbin/service postgresql initdb"
    if node.platform == "fedora" && node.platform_version.to_i >= 16
      initdb = "postgresql-setup initdb"
    end
    if ["redhat","centos"].include?(node.platform) && node.platform_version.to_i >= 6
      initdb = "/usr/pgsql-#{node.postgresql.version}/bin/initdb"
    end
    execute "rm -fr #{node.postgresql.dir}/*"
    execute "#{initdb}" do
      environment 'PGDATA' => node.postgresql.dir
      user "postgres"
    end
  end
  
  include_recipe "postgresql::gen_config"  
  
  ruby_block 'promote' do
    block do    
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)     
      is_in_recovery_cmd = shell_out('sudo -u postgres '+pg_bin+'/psql -t -c "SELECT pg_is_in_recovery();"|xargs')
      Chef::Log.info("is_in_recovery out: #{is_in_recovery_cmd.stdout}")
      Chef::Log.info("is_in_recovery err: #{is_in_recovery_cmd.stderr}")
      is_in_recovery_cmd.error!
      
      if is_in_recovery_cmd.stdout.gsub("\n","") == "t"
        promote_cmd = shell_out('sudo -u postgres '+pg_bin+"/pg_ctl promote -D #{node.postgresql.dir}")
        Chef::Log.info("promote out: #{promote_cmd.stdout}")
        Chef::Log.info("promote err: #{promote_cmd.stderr}")
        promote_cmd.error!

        sleep 10
        # need to restart else will get:
        # pg_basebackup: could not connect to server: FATAL:  number of requested standby connections exceeds max_wal_senders (currently 0)
        restart_cmd = shell_out("service postgresql-#{node.postgresql.version} restart")
        Chef::Log.info("restart out: #{restart_cmd.stdout}")
        Chef::Log.info("restart err: #{restart_cmd.stderr}")
        restart_cmd.error!      

      end
            
    end
  end 
     
else 
  is_hot_standby = true
  master_ip = master[:ciAttributes][:private_ip]

  restore_conf_file = data_dir + '/recovery.conf'
  restore_conf_file_content = ""
  is_in_recovery = false
  
  ruby_block 'check_is_in_recovery' do
    block do    
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)     
      is_in_recovery_cmd = shell_out('sudo -u postgres '+pg_bin+'/psql -t -c "SELECT pg_is_in_recovery();"|xargs')
      Chef::Log.info("is_in_recovery out: #{is_in_recovery_cmd.stdout}")
      Chef::Log.info("is_in_recovery err: #{is_in_recovery_cmd.stderr}")
      is_in_recovery_cmd.error!
      is_in_recovery = true if is_in_recovery_cmd.stdout.gsub("\n","") == "t"
      if ::File.exist?(restore_conf_file)
        recovery_conf_cmd = shell_out("cat #{restore_conf_file}")
        restore_conf_file_content = recovery_conf_cmd.stdout
      end
    end
  end
      
  if is_in_recovery && restore_conf_file_content.include?("host=#{master_ip} ")
    Chef::Log.info("already a standby to: "+master_ip)    
  else
    Chef::Log.info("configuring as a standby to: "+master_ip)
    
    # stop first 
    if ["redhat","centos"].include?(node.platform) && node.platform_version.to_i >= 6
      service "postgresql-#{node.postgresql.version}" do
        pattern "postgres: writer"
        action :stop
      end
    else
      service "postgresql" do
        service_name "postgresql"
        pattern "postgres: writer"
        action :stop
      end 
    end      

    # clear old dir
    execute "rm -fr #{data_dir}/*"
  
    # get base backup
    execute "#{pg_bin}/pg_basebackup -D #{data_dir} -x -h #{master_ip} -U replicator" do
      user "postgres"
    end
    
    # create recovery.conf to setup streaming
    recovery_conf = "standby_mode = 'on'\n"
    recovery_conf += "primary_conninfo = 'host=#{master_ip} port=5432 user=replicator password=replicator'\n"
    file restore_conf_file do
      owner "postgres"
      content recovery_conf
    end

    template "#{node[:postgresql][:dir]}/pg_hba.conf" do
      source "pg_hba.conf.erb"
      owner "postgres"
      group "postgres"
      mode 0600
    end

    template "#{node[:postgresql][:dir]}/postgresql.conf" do
      source "postgresql.conf.erb"
      owner "postgres"
      group "postgres"
      mode 0600
    end

  end
end   



# non-multizone don't have the attr
if node.workorder.cloud.ciAttributes.has_key?("priority") && 
   node.workorder.cloud.ciAttributes.priority == "1"
  
  # get this node's ip
  this_compute = node.workorder.payLoad[:ManagedVia][0]
  ip_addr = this_compute[:ciAttributes][:private_ip]
  
  slave_ips = Array.new
  # get slave ip addr from RequiresComputes
  computes = node.workorder.payLoad[:RequiresComputes]  
  Chef::Log.info("compute count: #{computes.size.to_s}" )
  computes.each do |compute|
    if compute[:ciAttributes][:private_ip] != ip_addr
      slave_ips.push compute[:ciAttributes][:private_ip]
    end
  end
  node.set[:postgresql][:slave_ips] = slave_ips

else
  Chef::Log.info("priority missing or != 1" )  
  node.set[:postgresql][:slave_ips] = Array.new  
end

mount_point = ""
original_data_dir = ""
version = node.workorder.rfcCi.ciAttributes["version"]

depends_set.each do |depends_on|
  depends_on_type = depends_on["ciClassName"]
  depends_on_index = (depends_on["ciName"][-1,1]).to_i
  if depends_on_type =~ /Volume/ 

    mount_point = depends_on["ciAttributes"]["mount_point"]
    mount_point += "/pg"          
    if depends_on_index > 1
       is_standby_using_volume = true
       Chef::Log.info("instance is NOT primary")
       # slave will not have /db mounted
     else
       Chef::Log.info("instance is primary")   
     end
  end
end


if postgresql_conf.has_key?('data_directory')
  mount_point = data_dir
end

if ::File.exists?(File.join(mount_point, "PG_VERSION"))
  Chef::Log.info("data already moved...")          

elsif is_standby_using_volume == false && mount_point != ""
  
  Chef::Log.info("instance is primary with a defined filesystem ...will chown, chmod and move initial data") 
  
  Chef::Log.info("moving from #{node[:postgresql][:data]} to #{mount_point}") 
  bash "move data dir" do
    code <<-EOH
      mkdir -p #{mount_point}
      chmod 700 #{mount_point}
      mv #{node[:postgresql][:data]} #{node[:postgresql][:data]}.original
      cp -r #{node[:postgresql][:data]}.original/* #{mount_point}/
      chown -R postgres:postgres #{mount_point}
      ln -s #{mount_point} #{node[:postgresql][:data]}
    EOH
  end
    
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




if !is_standby_using_volume
  # start postgresql after all changes

  if ["redhat","centos"].include?(node.platform) && node.platform_version.to_i >= 6
    service "postgresql-#{node.postgresql.version}" do
      pattern "postgres: writer"
      action :start
    end
  else
    service "postgresql" do
      service_name "postgresql"
      pattern "postgres: writer"
      action :start
    end 
  end  
  
end

dev_package = "postgresql-server-dev-all"
if node.platform != "ubuntu"
  dev_package = "postgresql-server-devel"
  if node.postgresql.version.to_f >= 9
    dev_package = "postgresql#{node.postgresql.version.split('.').join}-devel"  
  end
end

package dev_package do 
  action :install
end

ruby_block  "add perfstat and replicator users and pg gem" do
  block do
    Chef::Log.info("adding replicator user for streaming replication")
    `sudo -u postgres psql -c "CREATE USER replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'replicator';"`
    
    Chef::Log.info("adding perfstat user for metrics") 
    `sudo -u postgres psql -a -c "CREATE USER perfstat WITH PASSWORD 'perfstat';"`
    `sudo -u postgres psql -a -c "GRANT ALL PRIVILEGES ON DATABASE template1 to perfstat;"`
 
    `gem install pg`

  end
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

