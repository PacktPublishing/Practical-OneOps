#
# Cookbook Name:: netscaler
# Recipe:: get_lbvserver
#
# Copyright 2013 Walmart Labs
#

n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)

require 'pp'

# via lb::status
node.loadbalancers.each do |lb|
  
  lbvserver_name = lb[:name]
  
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/lbvserver/#{lbvserver_name}").body)
  
  puts "lbvserver: #{lbvserver_name}"
  pp resp_obj["lbvserver"]
  puts "\n\n"
  
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lbvserver_name}").body)
  
  puts "servicegroup binding:"
  pp resp_obj["lbvserver_servicegroup_binding"]
  puts "\n\n"
  
  if !resp_obj["lbvserver_servicegroup_binding"].nil?
    resp_obj["lbvserver_servicegroup_binding"].each do |sg|
      sg_name = sg["servicegroupname"]
      
      puts "servicegroup: #{sg_name}"
      resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)
      pp resp_obj["servicegroup"]
    
      puts ""
      puts "servicegroupmembers of: #{sg_name} "    
      resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/servicegroup_servicegroupmember_binding/#{sg_name}").body)
      pp resp_obj["servicegroup_servicegroupmember_binding"]
      puts ""
  
    end
  end 

  
  if lbvserver_name =~ /SSL/

    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:get, 
      :path=>"/nitro/v1/config/sslvserver_sslcertkey_binding/#{lbvserver_name}").body)

    puts "ssl certs:"
    pp resp_obj["sslvserver_sslcertkey_binding"]
      
  end    

end
