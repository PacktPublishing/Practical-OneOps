#
# Cookbook Name:: f5-bigip
# Recipe:: add_server
#
# Copyright 2013 Walmart Labs
#
chef_gem 'soap4r-spox' do
  version '1.6.0'
end

cookbook_file "#{Chef::Config[:file_cache_path]}/f5-icontrol.gem" do
	source 'f5-icontrol-11.4.1.0.gem'
end

resources(:cookbook_file => "#{Chef::Config[:file_cache_path]}/f5-icontrol.gem").run_action(:create)


chef_gem 'f5-icontrol' do
	source "#{Chef::Config[:file_cache_path]}/f5-icontrol.gem"
	version '11.4.1.0'
end



Chef::Recipe.send(:include, F5::Loader)

def check_for_lbvserver(f5_host,lbvserver_name)
  vs = search_virtual_server("#{f5_host}").ltm.virtual_servers.find { |v| v.name =~ /(^|\/)"#{lbvserver_name}"$/ }
  return true if !vs.nil?
  return false
end


  cloud_name = node[:workorder][:cloud][:ciName]
  if node[:workorder][:services].has_key?(:lb)
    cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
  else
    cloud_service = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]
  end
    
  if node.workorder.has_key?("rfcCi")
    ci = node.workorder.rfcCi
    action = node.workorder.rfcCi.rfcAction
    if node.has_key?("rfcAction")
      action = node.rfcAction
    end
    Chef::Log.info("action: #{action}")
  else
    ci = node.workorder.ci
    action = "action"
  end
  
  az_orig = ci[:ciAttributes][:availability_zone] || ''
  az = ci[:ciAttributes][:availability_zone] || ''
  az_map = JSON.parse(cloud_service[:availability_zones])
  az_ip_range_map = JSON.parse(cloud_service[:az_ip_range_map])
  manifest_ci = node.workorder.payLoad[:RealizedAs].first
  manifest_az = ""
  if !manifest_ci[:ciAttributes][:required_availability_zone].nil?
    manifest_az = manifest_ci[:ciAttributes][:required_availability_zone].gsub(/\s+/,"")
  end    
  
  if !manifest_az.empty?
    az = manifest_az
    if az_orig != az
      puts "***RESULT:availability_zone=#{az}"
    end      
  end
  
  # if az is empty then gen index using manifest id mod az map keys size
  if manifest_az.empty? && (action == "add" || action == "replace")
    index =  manifest_ci[:ciId] % az_map.keys.size
    Chef::Log.info("manifest.Lb ciId: #{manifest_ci[:ciId]} index: #{index}" )  
    az = az_map.keys[index]
    
    existing_az = ""
    found = false
    az_map.keys.each do |check_az|
      host = az_map[check_az]
      node.dcloadbalancers.each do |lb|
        if check_for_lbvserver(host,lb[:name]) 
          Chef::Log.info("found existing dc vip: #{lb[:name]} on az: #{check_az} - will use it.")
          az = check_az
          found = true
          break
        end
      end
      break if found
    end
    
    if az_map.has_key?(az)
      node.set["ns_ip_range"] = az_ip_range_map[az]
      Chef::Log.info("using az: #{az} ip_range: #{az_ip_range_map[az]}")   
      host = az_map[az]
      puts "***RESULT:availability_zone=#{az}"
    else
      Chef::Log.error("cloud: #{cloud_name} missing az: #{az}")
      exit 1
    end
  else    
    if az.empty? && action == "delete" && node.workorder.rfcCi.ciBaseAttributes.has_key?("availability_zone")
      Chef::Log.info("delete and changed az to empty - could be via a replace from a specific az to random/maniest id based")
      az = node.workorder.rfcCi.ciBaseAttributes.availability_zone
      Chef::Log.info("using previous az: #{az}")
    end
    if !az_map.has_key?(az) || !az_ip_range_map.has_key?(az)
      Chef::Log.error("invalid az: #{az}")
      exit 1
    end
    host = az_map[az]
    node.set["ns_ip_range"] = az_ip_range_map[az]      
    Chef::Log.info("using az: #{az} ip_range: #{az_ip_range_map[az]}")   
      
  end
  
  # az change
  if node.workorder.has_key?("rfcCi") && 
     node.workorder.rfcCi.ciAttributes.has_key?("required_availability_zone") &&
     node.workorder.rfcCi.ciAttributes.has_key?("availability_zone") &&
     node.workorder.rfcCi.ciAttributes.required_availability_zone != 
       node.workorder.rfcCi.ciAttributes.availability_zone && az_orig != az
  
    host_old = az_map[node.workorder.rfcCi.ciAttributes.availability_zone]
    Chef::Log.info("previous f5-bigip: #{host_old}")
#    node.set["ns_conn_prev"] = gen_conn(cloud_service,host_old)
  end
  
  # ns host
  Chef::Log.info("f5-bigip: #{host}")
#  node.set["ns_conn"] = gen_conn(cloud_service,host)
  node.set["gslb_local_site"] = cloud_service[:gslb_site]

computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/}
computes.each do |compute|

  ip = compute["ciAttributes"]["private_ip"] 
  server_key = ip
  next if ip.nil?

  if compute["ciAttributes"].has_key?("instance_name") &&
    !compute["ciAttributes"]["instance_name"].empty?
    
    server_key = compute["ciAttributes"]["instance_name"]
  end
  
  Chef::Log.info( "server_key: #{server_key}")

  node.set["f5_host"] = host

  f5_config_sync node.f5_host
  
  
  # check for server
  
  server = {:name => server_key, :ipaddress => ip }

  # ns nitro v1 api requires 'object=' string prefix
  req = 'object= { "server": '+JSON.dump(server)+'}'
  
 f5_ltm_node "#{server_key}" do
	node_name server_key
	f5 host
  	enabled true
  	address ip
  	notifies :run, "f5_config_sync[#{host}]", :delayed
 end 
end
