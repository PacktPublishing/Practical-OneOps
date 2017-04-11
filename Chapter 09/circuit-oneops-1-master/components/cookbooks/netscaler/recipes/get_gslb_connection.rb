#
# Cookbook Name:: netscaler
# Recipe:: get_connection
#
# Copyright 2013 Walmart Labs

require 'excon'

# return if re-invoked
if node.has_key?("ns_conn")
  return
end

cloud_name = node[:workorder][:cloud][:ciName]
if node[:workorder][:services].has_key?(:lb) && node[:workorder][:cloud][:ciAttributes][:location] !~ /azure/
  cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
else
  cloud_service = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]
end

host = cloud_service[:host]
Chef::Log.info("netscaler: #{host}")

encoded = Base64.encode64("#{cloud_service[:username]}:#{cloud_service[:password]}").gsub("\n","")
conn = Excon.new(
  'https://'+host, 
  :headers => {
    'Authorization' => "Basic #{encoded}", 
    'Content-Type' => 'application/x-www-form-urlencoded'
  },
  :ssl_verify_peer => false)

node.set["ns_conn"] = conn
node.set["ns_ip_range"] = cloud_service[:ip_range]
node.set["gslb_local_site"] = cloud_service[:gslb_site]
