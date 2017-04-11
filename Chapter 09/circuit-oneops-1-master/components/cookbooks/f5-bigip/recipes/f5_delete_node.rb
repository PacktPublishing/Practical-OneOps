#
# Cookbook Name:: f5-bigip
# Recipe:: f5_delete_node
#
# Copyright 2013 Walmart Labs


computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/}
computes.each do |compute|
	ip = compute["ciAttributes"]["private_ip"]
	server_key = ip
	next if ip.nil?
	if compute["ciAttributes"].has_key?("instance_name") &&
		!compute["ciAttributes"]["instance_name"].empty?

		server_key = compute["ciAttributes"]["instance_name"]
	end
	Chef::Log.info( "server_key: #{server_key}")
	f5_ltm_node "#{server_key}" do
		f5 "#{node.f5_host}"
		node_name server_key
		action :delete
		notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
	end
end
