#
# Cookbook Name:: f5-bigip
# Recipe:: f5_delete_lbvserver
#
# version          "0.1"
# maintainer       "OneOps"
# maintainer_email "support@oneops.com"
# license          "Apache License, Version 2.0"

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
  raction = node.workorder.rfcCi.rfcAction
  if node.has_key?("rfcAction")
    raction = node.rfcAction
  end
  Chef::Log.info("action: #{raction}")
else
  ci = node.workorder.ci
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
if manifest_az.empty? && (raction == "add" || raction == "replace")
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
  if az.empty? && raction == "delete" && node.workorder.rfcCi.ciBaseAttributes.has_key?("availability_zone")
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
    Chef::Log.info("previous f5: #{host_old}")
end

  # ns host
Chef::Log.info("f5: #{host}")

node.set["f5_host"] = host

f5_config_sync node.f5_host

#node.set["f5_host"] = '10.246.255.149'
lbs = node.loadbalancers + node.dcloadbalancers
lbs.each do |lb|

  lbvserver_name = lb['name']  
  f5_ltm_virtual_server "#{lbvserver_name}" do
    vs_name lbvserver_name
    f5  "#{node.f5_host}"
    action :delete
    notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
  end

end

include_recipe "f5-bigip::get_cert_name"

#Delete the SSL Profile
f5_ltm_sslprofiles  "#{node.cert_name}" do
  f5  "#{node.f5_host}"
  sslprofile_name "#{node.cert_name}"
  action :delete
  notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
end

#Delete the Certificate and Key Objects from F5
f5_ltm_ssl "#{node.cert_name}" do
  f5  "#{node.f5_host}"
  mode  "MANAGEMENT_MODE_DEFAULT"
  ssl_id  "#{node.cert_name}"
  action :delete
 notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
end


f5_ltm_ssl "#{node.cert_name}" do
  f5  "#{node.f5_host}"
  mode  "MANAGEMENT_MODE_DEFAULT"
  ssl_id  "#{node.cert_name}-alt"
  action :delete
 notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
end
