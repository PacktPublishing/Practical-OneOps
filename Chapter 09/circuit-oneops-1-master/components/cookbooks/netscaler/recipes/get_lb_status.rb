#
# Cookbook Name:: netscaler
# Recipe:: get_lbvserver
#
# Copyright 2013 Walmart Labs
#
require 'pp'

n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)


# via lb::status

full_detail = ""
pretty_detail = ""

node.loadbalancers.each do |lb|
  
  lbvserver_name = lb[:name]
    
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/lbvserver/#{lbvserver_name}").body)
  
  full_detail += "lbvserver: #{lbvserver_name}"
  lbo = resp_obj["lbvserver"][0]
  full_detail += PP.pp lbo, ""
  
  effective_level = "INFO"
  if lbo['effectivestate'] != "UP"
    effective_level = "ERROR"
  end
  puts "#{effective_level}: lbvserver: #{lbvserver_name}\n"
  puts "#{effective_level}: lbvserver: #{lbo['ipv46']}:#{lbo['port']} #{lbo['effectivestate']}\n"
      
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:get, 
    :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lbvserver_name}").body)

  bindings = resp_obj["lbvserver_servicegroup_binding"]
  
  full_detail += "servicegroup binding:"
  full_detail += PP.pp bindings, ""
  
  if !bindings.nil?
    !bindings.each do |sg|
      sg_name = sg["servicegroupname"]            
      resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/servicegroup/#{sg_name}").body)
      sgo = resp_obj["servicegroup"][0]

      full_detail += "servicegroup: #{sg_name}"
      full_detail += PP.pp sgo, ""

      resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/servicegroup_servicegroupmember_binding/#{sg_name}").body)
      sg_members = resp_obj["servicegroup_servicegroupmember_binding"]


      effective_level = "INFO"
      if !sg_members.nil?
        member_out_count = 0
        member_ok_count = 0
        sg_members.each do |member|
          if member['svrstate'] == "UP"
            member_ok_count += 1
          else
            member_out_count += 1
          end
        end
        if member_ok_count == 0
          effective_level = "ERROR"
        else
          if member_out_count > 0
            effective_level = "WARN"          
          end
        end

      end
      puts "#{effective_level}: servicegroup: #{sg_name}\n"
            
      full_detail += "servicegroupmembers of: #{sg_name}\n" 
      full_detail += PP.pp sg_members, ""
      
      if !sg_members.nil?
        sg_members.each do |member|

          effective_level = "INFO"
          if member['svrstate']!= "UP"
            effective_level = "ERROR"
          end
          puts "#{effective_level}: member: #{member['ip']}:#{member['port']} #{member['svrstate']}\n"
        end
      end

      resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, 
        :path=>"/nitro/v1/config/servicegroup_lbmonitor_binding/#{sg_name}").body)
      sg_monitors = resp_obj["servicegroup_lbmonitor_binding"]

      sg_monitors.each do |mon|
          mon_name = mon["monitor_name"]
          resp_obj = JSON.parse(node.ns_conn.request(:method=>:get, :path=>"/nitro/v1/config/lbmonitor/#{mon_name}").body)
          monitor = resp_obj["lbmonitor"][0]    
          puts "INFO: monitor: #{mon_name} #{monitor['httprequest']}\n"
          full_detail += "monitor:\n"
          full_detail += PP.pp monitor, ""          
      end      
  
    end
  end 

  
  if lbvserver_name =~ /SSL/ && lbvserver_name !~ /BRIDGE/

    resp_obj = JSON.parse(node.ns_conn.request(
      :method=>:get, 
      :path=>"/nitro/v1/config/sslvserver_sslcertkey_binding/#{lbvserver_name}").body)

    if resp_obj["sslvserver_sslcertkey_binding"].nil?
      puts "ERROR:  missing the sslvserver_sslcertkey_binding"
    else
      cert_binding = resp_obj["sslvserver_sslcertkey_binding"][0]
      full_detail += "ssl certs:"
      full_detail += PP.pp cert_binding, ""
      puts "info: sslcertkey: #{cert_binding['certkeyname']}\n"
    end
      
  end    

end



if Chef::Log.level == :debug
  Chef::Log.info("level: #{Chef::Log.level}")
  puts "###### Full Detail ######"
  puts full_detail
end
