env_name = node.workorder.payLoad.Environment[0]["ciName"]
platform_name = node.workorder.box.ciName
cloud_name = node.workorder.cloud.ciName
ci = node.workorder.payLoad.DependsOn[0]

# q5-ems-az1-gslbsrvc
# env-platform-zone-gslbsrvc
gslb_service_name = [env_name, platform_name, cloud_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
Chef::Log.info( "gslb_service_name: #{gslb_service_name}")
node.set["gslb_service_name"] = gslb_service_name
