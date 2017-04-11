#
# Cookbook Name:: netscaler
# Recipe:: delete_gslb_service
#
# Copyright 2013 Walmart Labs


include_recipe "netscaler::get_gslb_connection"
include_recipe "netscaler::get_gslb_service_name_by_platform"
include_recipe "netscaler::get_gslb_vserver_name_by_platform"

cloud_name = node.workorder.cloud.ciName
local_cloud_service = node[:workorder][:services][:gdns][cloud_name]

gdns = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]

gslb_service_name = node["gslb_service_name"]

# this could be a compute/server or lb
ci = node.workorder.payLoad.DependsOn[0]
server_ip = ci["ciAttributes"]["dns_record"]

# neteng wants this to make troubleshooting easier
fake_server_name = gslb_service_name +"."+node.gslb_base_domain
n = netscaler_server fake_server_name do
  name fake_server_name
  ipaddress server_ip
  connection node.ns_conn
  action :nothing  
end
n.run_action(:delete)

# delete gslb_service and binding
n = netscaler_gslb_service gslb_service_name do
  sitename gdns[:gslb_site]
  gslb_vserver node.gslb_vserver_name
  servername fake_server_name
  serverip server_ip  
  servicetype "HTTP"
  port 80
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
  
  remote_sites_done.push host

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
  n.run_action(:delete)
  
  # create gslb_service and binding
  n = netscaler_gslb_service gslb_service_name do
    sitename gdns[:gslb_site]
    gslb_vserver node.gslb_vserver_name
    servername fake_server_name
    serverip server_ip
    servicetype "HTTP"
    port 80
    connection conn  
    action :nothing  
  end
  n.run_action(:delete)  

end


authoritative_servers = JSON.parse(local_cloud_service[:ciAttributes][:gslb_authoritative_servers])

authoritative_servers.each do |dns_server|
  # skip if local or done already
  next if dns_server == local_cloud_service[:ciAttributes][:host]
  next if remote_sites_done.include?(dns_server)
  
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
  n.run_action(:delete)
  
  # create gslb_service and binding
  n = netscaler_gslb_service gslb_service_name do
    sitename gdns[:gslb_site]
    gslb_vserver node.gslb_vserver_name
    servername fake_server_name
    serverip server_ip
    servicetype "HTTP"
    port 80
    connection conn  
    action :nothing
  end
  n.run_action(:delete)  

end