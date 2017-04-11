#
# Cookbook Name:: netscaler
# Recipe:: get_dc_lbvserver
#
# gets dc-level vip from bom.Lb vnames
#

cloud_name = node.workorder.cloud.ciName
cloud_service = nil
dns_service = nil
if !node.workorder.services["gdns"].nil? &&
  !node.workorder.services["gdns"][cloud_name].nil?
  
  cloud_service = node.workorder.services["gdns"][cloud_name]
  dns_service = node.workorder.services["dns"][cloud_name]
end

if cloud_service.nil? || dns_service.nil?
  Chef::Log.error("missing cloud service. services: "+node.workorder.services.inspect)
  exit 1
end

if !cloud_service[:ciAttributes].has_key?("gslb_site_dns_id")
  msg = "gdns service for #{cloud_name} needs gslb_site_dns_id attr populated"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
platform = node.workorder.box
platform_name = platform[:ciName]

env_name = node.workorder.payLoad.Environment[0]["ciName"]
asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
org_name = node.workorder.payLoad.Organization[0]["ciName"]
dc_dns_zone = cloud_service[:ciAttributes][:gslb_site_dns_id]+"."+dns_service[:ciAttributes][:zone]
dc_dns_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".")

lbs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Lb/}
if lbs.nil? || lbs.size==0
  Chef::Log.info("no bom.Lb in DependsOn payload")
  return
end
lb = lbs.first
listener = JSON.parse(lb["ciAttributes"]["listeners"]).first
listener_parts = listener.split(" ")
service_type = listener_parts[0].upcase
if service_type == "HTTPS"
  service_type = "SSL"
end

vport = listener_parts[1]

# dc lb - example: web.prod-1312.core.oneops.dfw.prod.walmart.com-SSL_BRIDGE_443tcp-lb
dc_lb_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".") + 
             '-'+service_type+"_"+vport+"tcp-" + platform[:ciId].to_s + "-lb"

puts "dc_lb_name: #{dc_lb_name}"
                             
dc_vip = JSON.parse(lb[:ciAttributes][:vnames])[dc_lb_name]
if dc_vip.nil?
  Chef::Log.error("cannot get dc vip for: #{cloud_name}")
  exit 1
end

node.set["dc_lbvserver_name"] = dc_lb_name
node.set["dc_vip"] = dc_vip
node.set["dc_entry"] = {:name => dc_dns_name, :values => [dc_vip]}
