
include_recipe "rabbitmq_cluster::default"

if node.current_hostname == node.selected_hostname
	include_recipe "rabbitmq_cluster::replace_selected_node"
else
	include_recipe "rabbitmq_cluster::replace_non_selected_node"	
end

directory "/tmp/ssh" do
	recursive true
	action :delete
end
