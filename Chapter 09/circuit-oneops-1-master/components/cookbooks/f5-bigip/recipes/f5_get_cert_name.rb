#
# construct monitor name
#

env_name = node.workorder.payLoad.Environment[0]
assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
platform_name = node.workorder.box.ciName

cert_name = [env_name, assembly_name, platform_name, node.workorder.rfcCi.ciId.to_s].join("-") 

 truncate for f5-bigip max cert name length of 31
if cert_name.length > 31
  cert_name = "oo-"+node.workorder.rfcCi.ciId.to_s 
end

node.set["cert_name"] = cert_name
