if node.workorder.has_key?("rfcCi")
	ci = node.workorder.rfcCi
else
	ci = node.workorder.ci
end

node.loadbalancers.each do |lb|
	cloud_name = node[:workorder][:cloud][:ciName]
	if node[:workorder][:services].has_key?(:lb)
		cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
	else
		cloud_service = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]
	end
	az = ci[:ciAttributes][:availability_zone]
	az_map = JSON.parse(cloud_service[:availability_zones])
	f5_host = az_map[az]

	lbparts = lb['name'].split("-")
	lbparts.pop
	base_pool_name =  "str-" + lbparts.join("-") + "-pool"

	profiles_list = [{ 'profile_context' =>  'PROFILE_CONTEXT_TYPE_ALL', 'profile_name'     => "/Common/tcp"}]
	profiles_list = [{ 'profile_context' =>  'PROFILE_CONTEXT_TYPE_ALL', 'profile_name'     => "/Common/http"}] if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)

	f5_ltm_virtual_server "#{lb[:name]}" do
		vs_name lb[:name]
		default_pool base_pool_name
		f5 f5_host
		profiles profiles_list
		destination_address node.lb_details[lb["name"]]
		destination_port lb[:vport]
		connection_limit 12
		enabled true
		do_not_overwrite true
	end
	
end