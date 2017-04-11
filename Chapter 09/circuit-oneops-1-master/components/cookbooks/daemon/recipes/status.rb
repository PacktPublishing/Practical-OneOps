#
# Cookbook Name:: daemon
# Recipe:: status
#
service_name = node.workorder.ci.ciAttributes[:service_name]

ruby_block "status #{service_name} service" do
	block do
		Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
		shell_out!("service #{service_name} status ", :live_stream => Chef::Log::logger)
    end
end
