
cloud_name = node.workorder.cloud.ciName
dns_service = nil
if !node.workorder.services["lb"].nil? &&
    !node.workorder.services["lb"][cloud_name].nil?
  dns_service = node.workorder.services["dns"][cloud_name]
end

platform_name = node.workorder.box.ciName
env_name = node.workorder.payLoad.Environment[0]["ciName"]
dns_zone = dns_service[:ciAttributes][:zone]
ci = {}
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

node.set["lb_name"] = [env_name, platform_name, dns_zone].join(".") + '-'+"tcp" +'-' + ci[:ciId].to_s + "-lb"
