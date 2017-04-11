#
# Cookbook Name:: netscaler
# Recipe:: add_gslb_service
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

include_recipe "netscaler::get_gslb_connection"
include_recipe "netscaler::get_gslb_service_name_by_platform"

cloud_name = node.workorder.cloud.ciName
local_cloud_service = node[:workorder][:services][:gdns][cloud_name]
gdns = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]

node.set["gslb_has_changes"] = false


# this could be a compute/server or lb
ci = node.workorder.payLoad.DependsOn[0]
# was by cloud-level vip
# server_ip = ci["ciAttributes"]["dns_record"]
server_ip = node.dc_vip

gslb_service_name = node["gslb_service_name"]
gslb_service_state = "ENABLED"

# default / use 80 if exists
gslb_port = 80
instance_port = 80
gslb_protocol = "HTTP"
lb = node.workorder.payLoad.lb.first
listeners = JSON.parse( lb[:ciAttributes][:listeners] )
listeners.each do |l|
  lb_attrs = l.split(" ") 
  gslb_protocol = lb_attrs[0].upcase
  if gslb_protocol == "HTTPS"
    gslb_protocol = "SSL"
  end
  gslb_port = lb_attrs[1].to_i
  instance_port = lb_attrs[3].to_i
  break if gslb_protocol == "HTTP"
end

# no longer cloud level - now the servicegroup is (un)bound to lbvserver 
# when the cloud is not primary
#if node.workorder.cloud.ciAttributes.priority.to_i != 1
#  gslb_service_state = "DISABLED"
#end

# neteng wants this to make troubleshooting easier
fake_server_name = gslb_service_name +"."+node.gslb_base_domain
n = netscaler_server fake_server_name do
  name fake_server_name
  ipaddress server_ip
  connection node.ns_conn
  action :nothing
end
n.run_action(:create)  

# create gslb_service and binding
n = netscaler_gslb_service gslb_service_name do
  state gslb_service_state
  sitename gdns[:gslb_site]
  gslb_vserver node.gslb_vserver_name
  servername fake_server_name
  serverip server_ip
  servicetype gslb_protocol
  port gslb_port
  iport instance_port
  connection node.ns_conn  
  action :nothing  
end
n.run_action(:create)  

# remote sites

remote_sites = Array.new
node.workorder.payLoad.remotegdns.each do |service|
  if service[:ciAttributes].has_key?("gslb_site") && 
     service[:ciAttributes][:gslb_site] != local_cloud_service[:ciAttributes][:gslb_site] &&
     !service[:ciAttributes][:gslb_site].empty?

    remote_sites.push service
  end
end

remote_sites_done = Array.new

remote_sites.each do |cloud_service|

  username = cloud_service[:ciAttributes][:username]
  password = cloud_service[:ciAttributes][:password]
  host = cloud_service[:ciAttributes][:host]
  
  remote_sites_done.push(host)

  Chef::Log.info("connecting to netscaler: #{host}")
  encoded = Base64.encode64("#{username}:#{password}").gsub("\n","")
  conn = Excon.new('https://'+host, 
    :headers => {'Authorization' => "Basic #{encoded}", 'Content-Type' => 'application/x-www-form-urlencoded'},
    :ssl_verify_peer => false)

  # neteng wants this to make troubleshooting easier
  n = netscaler_server fake_server_name do
    name fake_server_name
    ipaddress server_ip
    connection conn
    action :nothing
  end
  n.run_action(:create)    
 
  # create gslb_service and binding
  n = netscaler_gslb_service gslb_service_name do
    state gslb_service_state
    sitename gdns[:gslb_site]
    gslb_vserver node.gslb_vserver_name
    servername fake_server_name
    serverip server_ip
    servicetype gslb_protocol
    port gslb_port
    connection conn  
    action :nothing    
  end
  n.run_action(:create)  

  n = netscaler_saveconfiglogout "save" do
    connection conn  
    action :nothing    
  end
  n.run_action(:default) if node.gslb_has_changes

end


authoritative_servers = JSON.parse(local_cloud_service[:ciAttributes][:gslb_authoritative_servers])

authoritative_servers.each do |dns_server|
  # skip if local or done already
  next if dns_server == local_cloud_service[:ciAttributes][:host]
  if remote_sites_done.include?(dns_server)
    Chef::Log.info("skipping because already did: #{dns_server}")
    next
  end
  
  Chef::Log.info("remote authoritative server: "+dns_server)
  
  username = local_cloud_service[:ciAttributes][:username]
  password = local_cloud_service[:ciAttributes][:password]
  host = dns_server

  Chef::Log.debug("connecting to netscaler: #{host}")
  encoded = Base64.encode64("#{username}:#{password}").gsub("\n","")
  conn = Excon.new('https://'+host, 
    :headers => {'Authorization' => "Basic #{encoded}", 'Content-Type' => 'application/x-www-form-urlencoded'},
    :ssl_verify_peer => false)

  # neteng wants this to make troubleshooting easier
  n = netscaler_server fake_server_name do
    name fake_server_name
    ipaddress server_ip
    connection conn
    action :nothing
  end
  n.run_action(:create)    
  
  # create gslb_service and binding
  n = netscaler_gslb_service gslb_service_name do
    state gslb_service_state
    sitename gdns[:gslb_site]
    gslb_vserver node.gslb_vserver_name
    servername fake_server_name
    serverip server_ip
    servicetype gslb_protocol
    port gslb_port
    connection conn
    action :nothing 
  end
  n.run_action(:create)  
  
  n = netscaler_saveconfiglogout "save" do
    connection conn  
    action :nothing    
  end
  n.run_action(:default) if node.gslb_has_changes
  

end
