#
# d1-pricing-gslbvserver
# env-platform-ci_id-gslbvserver 
#

# lb ci
ci = node.workorder.payLoad.DependsOn[0]
env_name = node.workorder.payLoad.environment[0]["ciName"]
platform_name = node.workorder.box.ciName

gslb_vserver_name = [env_name, platform_name, ci["ciId"].to_s , "gslb"].join("-")

node.set["gslb_vserver_name"] = gslb_vserver_name
