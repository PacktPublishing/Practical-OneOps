
cloud_ids = Array.new
hostnames = Array.new
hostnames_with_ips = Hash.new
platform_name = node.workorder.box.ciName
computes = node.workorder.payLoad.RequiresComputes

return "not joining to cluster as total number of computes are 1 only.. exiting" if computes.size == 1

node.workorder.payLoad.RequiresKeys.each do |k|
	cloud_ids.push(k[:ciName].split("-")[1])
end

node.workorder.payLoad.RequiresOs.each do |os|
	hostnames.push(os[:ciAttributes][:hostname])
end

hostnames.each do |h|
	ip = computes.select { |c| h.include?("#{c[:ciName].gsub('compute-','')}") }[0][:ciAttributes][:private_ip]
	hostnames_with_ips["#{ip}"] = h
end

hostnames_with_ips.each do |ip, host|
	execute "ghost modify #{host} #{ip}"
end

node.set[:current_hostname] = node.workorder.payLoad.DependsOn.select { |c| c["ciClassName"] =~ /Os/}[0]["ciAttributes"]["hostname"]
node.set[:current_ip] = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]
node.set[:hostnames] = hostnames
node.set[:selected_hostname] = node.hostnames.min
node.set[:selected_ip] = hostnames_with_ips.select { |ip, host| host == node.selected_hostname }.keys[0]
node.set[:selected_cloud_id] = node.selected_hostname.gsub("#{platform_name}-","").split("-")[0]
node.set[:cloud_ids] = cloud_ids

Chef::Log.info("current_hostname: #{node.current_hostname}")
Chef::Log.info("current_ip: #{node.current_ip}")
Chef::Log.info("selected_hostname: #{node.selected_hostname}")
Chef::Log.info("selected_ip: #{node.selected_ip}")
Chef::Log.info("selected_cloud_id: #{node.selected_cloud_id}")
Chef::Log.info("cloud_ids: #{cloud_ids.inspect}")
Chef::Log.info("hostnames_with_ips: #{hostnames_with_ips.inspect}")

directory "/tmp/ssh" do
	action :create
end

include_recipe "rabbitmq_cluster::host_resolution"
