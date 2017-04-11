#
# Cookbook Name:: netscaler
# Recipe:: delete_gslb_vserver
#
# Copyright 2013 Walmart Labs

require 'excon'

include_recipe "netscaler::get_gslb_connection"
include_recipe "netscaler::get_gslb_vserver_name_by_platform"
include_recipe "netscaler::get_gslb_domain"

cloud_name = node.workorder.cloud.ciName
local_cloud_service = node[:workorder][:services][:gdns][cloud_name]
gdns = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]




# create gslb_server and bind domain if platform is active
n = netscaler_gslb_vserver node.gslb_vserver_name do
  servicetype "HTTP"
  dnsrecordtype "A"
  lbmethod "ROUNDROBIN"
  domain node.gslb_domain
  connection node.ns_conn  
  action :nothing  
end
n.run_action(:delete)  

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
    servicetype "HTTP"
    dnsrecordtype "A"
    lbmethod "ROUNDROBIN"
    domain node.gslb_domain
    connection conn  
    action :nothing  
  end
  n.run_action(:delete) 

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
    servicetype "HTTP"
    dnsrecordtype "A"
    lbmethod "ROUNDROBIN"
    domain node.gslb_domain
    connection conn  
    action :nothing  
  end
  n.run_action(:delete) 

end
