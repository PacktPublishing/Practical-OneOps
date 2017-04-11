#
# Cookbook Name:: netscaler
# Recipe:: get_lbvserver
#
# Copyright 2013 Walmart Labs
#

include_recipe "netscaler::get_gslb_connection"

require 'pp'

full_detail = ""

# via lb::status
node.loadbalancers.each do |lb|
  
  gslbvserver_name = lb[:name]
  
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver/#{gslbvserver_name}").body)
  
  gslb = resp_obj["gslbvserver"][0]
  
  
  effective_level = "info"
  if gslb['curstate'] != "UP"
    effective_level = "error"
  end
  puts "#{effective_level}: gslbvserver: #{gslbvserver_name} #{gslb['curstate']}"
  
  full_detail += PP.pp gslb,""
  
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/gslbvserver_gslbservice_binding/#{gslbvserver_name}").body)
  
  full_detail += "gslb service binding:"
  full_detail += PP.pp resp_obj["gslbvserver_gslbservice_binding"],""
  
  resp_obj["gslbvserver_gslbservice_binding"].each do |s|
    s_name = s["servicename"]
    
    effective_level = "info"
    if s['curstate'] != "UP"
      effective_level = "error"
    end
    puts "#{effective_level}: gslbservice: #{s['servicename']} #{s['ipaddress']}:#{s['port']}  #{s['curstate']}"
    
    puts "servicename: #{s_name}"
    resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/gslbservice/#{s_name}").body)
    full_detail += PP.pp resp_obj["gslbservice"],""
  
  end

end

if Chef::Log.level == :debug
  Chef::Log.info("level: #{Chef::Log.level}")
  puts "###### Full Detail ######"
  puts full_detail
end
