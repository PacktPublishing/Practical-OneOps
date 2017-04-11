#
# Cookbook Name:: crm
# Recipe:: add
#
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

# number retries for backend calls
max_retry_count = 5
group_map = Hash.new
is_primary = false
is_active_active = false


ifconfig_out = `ifconfig eth0`
if ifconfig_out =~ /Bcast:(.*?) /
  node.set["bcast_addr"] = $1
  Chef::Log.info("bcast_addr: #{node['bcast_addr']}")
end

if node.platform == "ubuntu" && node.platform_version == "10.04"
  Chef::Log.info("ubuntu-10.04: add-apt-repository ppa:ubuntu-ha-maintainers/ppa ...") 
  `add-apt-repository ppa:ubuntu-ha-maintainers/ppa`
  `apt-get -y update`  
end


# packages for clustering
pkgs = value_for_platform(
    ["debian","ubuntu"] => { "default" => ["corosync", "pacemaker", "libxml2-dev", "libxslt-dev"] },
                             "default" => ["corosync", "pacemaker", "libxml2-devel", "libxslt-devel", "bind-utils"]
)
pkgs.each do |pkg|
    package pkg do
        action :install
    end
end

service "iptables" do
  action [:stop, :disable]
end


ruby_block 'ordered cleanup' do
  block do
    
    if node.platform == "ubuntu"
      Chef::Log.info("for ubuntu - bug workaround : echo \"START=yes\" > /etc/default/corosync ...")
      `echo "START=yes" > /etc/default/corosync`      
    end

  end
end

  
template "/etc/init.d/elastic-ip" do
  source "elastic-ip.erb"
  owner "root"
  group "root"
  mode "0744"
end

template "/etc/init.d/cluster-by-dns" do
  source "cluster-by-dns.erb"
  owner "root"
  group "root"
  mode "0744"
end

template "/etc/init.d/ebs" do
  source "ebs-init.erb"
  owner "root"
  group "root"
  mode "0744"
end

template "/usr/lib/ocf/resource.d/heartbeat/ebs" do
  source "ebs-ocf.erb"
  owner "root"
  group "root"
  mode "0744"
end


template "/etc/corosync/corosync.conf" do
  source "corosync.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

service "corosync" do
  action [:restart, :enable]
end

deps = node.workorder.payLoad.DependsOn
deps.each do |dep|
  # cleanup upstart for mysql so it doesnt auto-respawn w/ ocf script
  if dep["ciClassName"] =~ /Mysql/
    service "mysql" do
      action :stop
    end
    execute "remove mysql upstart respawn config" do
      command "rm -fr /etc/init/mysql.conf"
    end    
  end
end


template "/etc/init.d/mysql" do
  source "mysql.erb"
  owner "root"
  group "root"
  mode "0744"
end

# fix for mysql ubuntu : uses /etc/mysql/my.cfg
template "/usr/lib/ocf/resource.d/heartbeat/mysql" do
  source "mysql-ocf.erb"
  owner "root"
  group "root"
  mode "0744"
end

# standby non '-1' so we don't randomly failover ebs, eip at the beginning
ruby_block 'standby-if-not-primary' do
  block do    
    if node.workorder.rfcCi.ciName[-1,1] != '1'      
      Chef::Log.info("sleeping for 60sec for corosync to sync...")
      sleep(60)
      hostname = `hostname`.chop
      cmd = "crm node standby #{hostname}"
      Chef::Log.info("#{cmd}: "+`#{cmd}`)
      cmd = "crm node show"
      Chef::Log.info("#{cmd}: "+`#{cmd}`.gsub("\n","") )

    end
  end
end
