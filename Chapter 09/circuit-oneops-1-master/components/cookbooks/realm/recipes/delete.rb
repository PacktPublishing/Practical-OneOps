ci = node.workorder.rfcCi
node.set[:realm] = ci.nsPath.split("/")[1..3].join("-").to_s

cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["container"].nil? &&
  !node.workorder.services["container"][cloud_name].nil?
  cloud_service = node.workorder.services["container"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.fatal("no container cloud service defined. services: "+node.workorder.services.inspect)
end

Chef::Log.info("Container Cloud Service: #{cloud_service[:ciClassName]}")


case cloud_service[:ciClassName].split(".").last.downcase
when /kubernetes/
  include_recipe "kubernetes::delete_realm"
when /swarm/
  include_recipe "swarm::delete_realm"
when /ecs/
  include_recipe "ecs::delete_realm"
else
  raise "Container Cloud Service: #{cloud_service[:ciClassName]}"
end
