
env_name = node.workorder.payLoad["Environment"][0]["ciName"]
cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["lb"].nil? &&
    !node.workorder.services["lb"][cloud_name].nil?

  cloud_service = node.workorder.services["lb"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.error("no cloud service defined. services: "+node.workorder.services.inspect)
  exit 1
end
case cloud_service[:ciClassName].split(".").last.downcase
  when /neutron/
    include_recipe "lb::build_load_balancers"
    include_recipe "neutron::update"

  when /netscaler/
    include_recipe "lb::add"
end
