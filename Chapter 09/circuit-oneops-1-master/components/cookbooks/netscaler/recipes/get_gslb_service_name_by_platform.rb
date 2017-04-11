env_name = node.workorder.payLoad.Environment[0]["ciName"]
platform_name = node.workorder.box.ciName
cloud_name = node.workorder.cloud.ciName
asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
gdns_cloud_service = node.workorder.services["gdns"][cloud_name]
dc_name = gdns_cloud_service[:ciAttributes][:gslb_site_dns_id]
ci = node.workorder.box

# q5-ems-az1-gslbsrvc
# env-platform-zone-gslbsrvc
# gslb service is a dc-level vip
gslb_service_name = [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
Chef::Log.info( "gslb_service_name: #{gslb_service_name}")
node.set["gslb_service_name"] = gslb_service_name
