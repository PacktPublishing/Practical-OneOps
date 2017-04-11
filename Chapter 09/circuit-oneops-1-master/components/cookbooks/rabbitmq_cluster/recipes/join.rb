
include_recipe "rabbitmq_cluster::app_stop" unless node.current_hostname == node.selected_hostname

ruby_block "joining #{node.current_hostname} with #{node.selected_hostname}" do
	block do
		Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
		execute_cmd = shell_out("rabbitmqctl join_cluster rabbit@#{node.selected_hostname}", :live_stream => Chef::Log::logger)
		Chef::Log.info "#{execute_cmd.stdout}" unless "#{execute_cmd.stdout}".empty?
		Chef::Log.error "#{execute_cmd.stderr}" unless "#{execute_cmd.stderr}".empty?
	end
	not_if { node.current_hostname == node.selected_hostname }
end

include_recipe "rabbitmq_cluster::app_start"
