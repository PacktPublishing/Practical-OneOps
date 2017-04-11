#
# Cookbook Name:: netscaler
# Recipe:: add_lbvserver
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

require 'excon'

include_recipe "netscaler::get_gslb_connection"
include_recipe "netscaler::get_gslb_vserver_name_by_platform"
include_recipe "netscaler::get_gslb_domain"

cloud_name = node.workorder.cloud.ciName
local_cloud_service = node[:workorder][:services][:gdns][cloud_name]
gdns = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]

lbmethod = "ROUNDROBIN"
if node.workorder.rfcCi.ciAttributes.has_key?("distribution")
  case node.workorder.rfcCi.ciAttributes.distribution
  when "proximity"
    lbmethod = "STATICPROXIMITY"
  when "latency"
    lbmethod = "RTT"
  end
end

# default / use 80 if exists
gslb_port = 80
gslb_protocol = "HTTP"
lb = node.workorder.payLoad.lb.first
listeners = JSON.parse( lb[:ciAttributes][:listeners] )
listeners.each do |l|
  lb_attrs = l.split(" ") 
  gslb_protocol = lb_attrs[0].upcase
  if gslb_protocol == "HTTPS"
    gslb_protocol = "SSL"
  end
  gslb_port = lb_attrs[1]
  break if gslb_protocol == "HTTP"
end
dnsrecordtype = ''
if node.workorder.payLoad.lb[0][:ciAttributes][:dns_record] =~ Resolv::IPv6::Regex
  dnsrecordtype = "AAAA"
else
  dnsrecordtype = "A"
end
Chef::Log.info ("dnsrecordtype: #{dnsrecordtype}")
# create gslb_server and bind domain if platform is active
n = netscaler_gslb_vserver node.gslb_vserver_name do
  servicetype gslb_protocol
  dnsrecordtype dnsrecordtype
  lbmethod lbmethod
  domain node.gslb_domain
  connection node.ns_conn  
  action :nothing  
end
n.run_action(:create)  


# remote sites
remote_sites = Array.new
node.workorder.payLoad.remotegdns.each do |service|
  if service[:ciAttributes].has_key?("gslb_site") && 
     service[:ciAttributes][:gslb_site] != local_cloud_service[:ciAttributes][:gslb_site]

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

 
  # create gslb_vserver and binding
  n = netscaler_gslb_vserver node.gslb_vserver_name do
    servicetype gslb_protocol
    dnsrecordtype dnsrecordtype
    lbmethod lbmethod
    domain node.gslb_domain
    connection conn  
    action :nothing  
  end
  n.run_action(:create)   

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

  # create gslb_vserver and binding
  n = netscaler_gslb_vserver node.gslb_vserver_name do
    servicetype gslb_protocol
    dnsrecordtype dnsrecordtype
    lbmethod lbmethod
    domain node.gslb_domain
    connection conn  
    action :nothing  
  end
  n.run_action(:create) 
  
end
