# Cookbook Name:: daemon
# Recipe:: stop
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

# stop daemon service when pattern has not been specified
ruby_block "stop #{service_name} service" do
	block do
    	Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    	shell_out!("service #{service_name} stop ", :live_stream => Chef::Log::logger)
	end
  	only_if { pat.empty? }
end

# stop daemon service when pattern has been specified
service "#{service_name}" do
	pattern "#{pat}"
	action :stop
	only_if { !pat.empty? }
end
