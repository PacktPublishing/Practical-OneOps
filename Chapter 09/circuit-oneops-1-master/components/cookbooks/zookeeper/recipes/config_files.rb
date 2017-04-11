#
# Cookbook Name::       zookeeper
# Description::         Config files -- include this last after discovery
# Recipe::              config_files
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2010, Infochimps, Inc.
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

#
# Config files
#
#zookeeper_hosts = discover_all(:zookeeper, :server).sort_by{|cp| cp.node[:facet_index] }.map(&:private_ip)

# use explicit value if set, otherwise make the leader a server iff there are
# four or more zookeepers kicking around

hostname = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep["ciClassName"] =~ /Fqdn/
    hostname = dep
    break
  end
end

Chef::Log.info("------------------------------------------------------")
Chef::Log.info("Hostname: "+hostname.inspect.gsub("\n"," "))
Chef::Log.info("------------------------------------------------------")

nodes = node.workorder.payLoad.RequiresComputes

cloud_map = Hash.new
ip_to_ciname_map = Hash.new
zookeeper_hosts = Hash.new
my_zk_id = nil

# build the mapping b/w ip to ciName
# build the cloud map
nodes.each do |n|
  ip_to_ciname_map.store(n[:ciAttributes][:dns_record], n[:ciName])
  if cloud_map.has_key?(n[:ciName].split("-")[1]) == false
    cloud_map.store(n[:ciName].split("-")[1], cloud_map.length)
  end
end

# check if hostname component exists
if hostname.nil?
  # if hostname is not enabled, use ip address in zoo.cfg
  # zk_id is the index (value part) of zookeeper_host, this should be backward compatible
  nodes.each do |n|
    zk_id = zookeeper_hosts.length + 1
    zookeeper_hosts.store(n[:ciAttributes][:dns_record], zk_id)
    if n[:ciAttributes][:dns_record] == node[:ipaddress]
      my_zk_id = zk_id
    end
  end
else
  # if hostname is enabled, get the hostname attributes
  if !hostname["ciBaseAttributes"]["entries"].nil? && !hostname["ciBaseAttributes"]["entries"].empty?
    attr = hostname["ciBaseAttributes"]
  else
    attr = hostname["ciAttributes"]
  end
  # check if ptr in hostname is enabled or not
  if attr["ptr_enabled"] == "false"
    # if ptr is not enabled, use ip address in zoo.cfg
    # because we cannot use PTR to get hostname
    # zk_id is the index (value part) of zookeeper_host, this should be backward compatible
    nodes.each do |n|
      zk_id = zookeeper_hosts.length + 1
      zookeeper_hosts.store(n[:ciAttributes][:dns_record], zk_id)
      if n[:ciAttributes][:dns_record] == node[:ipaddress]
        my_zk_id = zk_id
      end
    end
    else
      nodes.each do |n|
      ip = n[:ciAttributes][:dns_record]
      # calculate unique zookeeper id for this node, not the index
      # by using the following way of calculating the zookeeper id
      # now it is indepedent of the order returned by "node.workorder.payLoad.RequiresComputes"
      # zk_id cloud #1: 1, 2, 3, 4....
      # zk_id cloud #2: 101, 102, 103, 104....
      # zk_id cloud #3: 201, 202, 203, 204....
      ciName = ip_to_ciname_map[ip]
      array = ciName.split("-")
      zk_id = cloud_map[array[1]].to_i * 100 + array[2].to_i
      if n[:ciAttributes][:dns_record] == node[:ipaddress]
        my_zk_id = zk_id
      end
      tries = 0
      # DNS service may take some time to have the entry of IP -> hostname
      # so using a while loop to repeatly check every 5 seconds
      # timeout after 30 tries, then use ip address
      full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
      while tries < 30
        if full_hostname =~ /NXDOMAIN/
          tries +=1
          Chef::Log.info("unable to resolve hostname from IP by PTR, sleep 5s and retry: #{ip}, tries: #{tries}")
          sleep(5)
          full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
        else
          Chef::Log.info("full_hostname :" + full_hostname)
          zookeeper_hosts.store(full_hostname, zk_id);
          break
        end
      end
      # if time out, use ip address
      if tries == 30
        Chef::Log.info("Timed out - use IP address instead :" + n[:ciAttributes][:dns_record])
        zookeeper_hosts.store(n[:ciAttributes][:dns_record], zk_id)
      end
    end
  end
end

node.set[:string_of_hostname] = zookeeper_hosts.keys.join(" ")

# use explicit value if set, otherwise make the leader a server iff there are
# four or more zookeepers kicking around

leader_is_also_server = node[:zookeeper][:leader_is_also_server]
if (leader_is_also_server.to_s == 'auto')
    leader_is_also_server = (zookeeper_hosts.length >= 4)
end
# So that node IDs are stable, use the server's index (eg 'foo-bar-3' = zk id 3)
# If zookeeper servers span facets, give each a well-sized offset in facet_role
# # (if 'bink' nodes have zkid_offset 10, 'foo-bink-7' would get zkid 17)
# node[:zookeeper][:zkid]  = node[:facet_index]
# node[:zookeeper][:zkid] += node[:zookeeper][:zkid_offset].to_i if node[:zookeeper][:zkid_offset]

template_variables = {
  :zookeeper         => node[:zookeeper],
  :zookeeper_hosts   => zookeeper_hosts,
  :myid              => my_zk_id,
  :leader_is_also_server => leader_is_also_server,
}

%w[ zoo.cfg log4j.properties].each do |conf_file|
  template "#{node[:zookeeper][:conf_dir]}/#{conf_file}" do
  variables   template_variables
  owner       "root"
  mode        "0644"
  source      "#{conf_file}.erb"
  end
end

template "/var/zookeeper/data/myid" do
  owner         "zookeeper"
  mode          "0644"
  variables     template_variables
  source        "myid.erb"
end

template "#{node[:zookeeper][:home_dir]}/zookeeper-#{node[:zookeeper][:version]}/bin/zkEnv.sh" do
  owner         "zookeeper"
  mode          "0644"
  variables     template_variables
  source        "zkEnv.sh.erb"
end

template "#{node[:zookeeper][:home_dir]}/zookeeper-#{node[:zookeeper][:version]}/bin/zkServer.sh" do
  owner         "zookeeper"
  mode          "0755"
  variables     template_variables
  source        "zkServer.sh.erb"
end

template "/etc/init.d/zookeeper-server" do
  source "zookeeper-server.erb"
  owner "root"
  group "root"
  mode  "0755"
 variables     template_variables

end

