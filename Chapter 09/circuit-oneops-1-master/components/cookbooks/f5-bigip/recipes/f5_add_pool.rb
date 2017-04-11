#include_recipe 'f5-bigip::provision_configsync'
require_relative "../libraries/resource_config_sync"
require_relative "../libraries/resource_ltm_node"
require_relative "../libraries/resource_ltm_pool"

#lbs = [] +  node.dcloadbalancers
lbs = [] + node.loadbalancers + node.dcloadbalancers
env_name = node.workorder.payLoad.Environment[0]["ciName"]
assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
platform_name = node.workorder.box.ciName
cloud_name = node.workorder.cloud.ciName




lbCi = node.workorder.rfcCi
rfc = node.workorder.rfcCi.ciAttributes

lb_ci_id = lbCi["ciId"].to_s

include_recipe "f5-bigip::f5_add_monitor"
lbs.each do |lb|
  lbparts = lb['name'].split("-")
  lbparts.pop
  #base_monitor_name =  "str-" + lbparts.join("-") + "-monitor"
  base_monitor_name =  "str-" + [env_name, assembly_name, platform_name, lb['iport'], lb_ci_id].join("-") + "-monitor"
  base_pool_name =  "str-" + lbparts.join("-") + "-pool"

	lbmethod = node.workorder.rfcCi.ciAttributes.lbmethod
  lb_method = 'LB_METHOD_ROUND_ROBIN' if lbmethod == "roundrobin"
  lb_method = 'LB_METHOD_LEAST_CONNECTION_MEMBER' if lbmethod == "leastconn"
	sg_name = lb[:sg_name]
	members = []
	#Get all the computes/nodes(server_key) which were added as a part of add_server.rb
	computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/}
	computes.each do |compute|
		member = {}
  		ip = compute["ciAttributes"]["private_ip"] 
  		server_key = ip
  		next if ip.nil?

  		if compute["ciAttributes"].has_key?("instance_name") &&
    		!compute["ciAttributes"]["instance_name"].empty?
    
    		server_key = compute["ciAttributes"]["instance_name"]
  		end
  		member = {
  			"address"=> "#{server_key}",
  			"port" => lb['iport'].to_i,
  			"enabled" => true
  		}
  		members.push(member)
  	end
  f5_ltm_pool "#{base_pool_name}" do
      pool_name "#{base_pool_name}"
      f5 "#{node.f5_host}"
      lb_method "#{lb_method}"
      monitors [ "/Common/#{base_monitor_name}" ]
      members members
      notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
    end
end
