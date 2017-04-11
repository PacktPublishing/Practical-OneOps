#
# d1-pricing-gslbvserver
# env-platform-ci_id-gslbvserver 
#

# plaform ci
ci = node.workorder.box
env_name = node.workorder.payLoad.environment[0]["ciName"]
asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
platform_name = node.workorder.box.ciName

gslb_vserver_name = [env_name, platform_name, asmb_name, ci["ciId"].to_s , "gslb"].join("-")

node.set["gslb_vserver_name"] = gslb_vserver_name
