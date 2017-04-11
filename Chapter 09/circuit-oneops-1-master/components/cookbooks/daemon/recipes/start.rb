#
# Cookbook Name:: daemon
# Recipe:: start
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

# start daemon service when pattern has not been specified
ruby_block "start #{service_name} service" do
	block do
    	Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    	shell_out!("service #{service_name} start", :live_stream => Chef::Log::logger)
	end
  	only_if { pat.empty? }
end

# start daemon service when pattern has been specified
service "#{service_name}" do
	pattern "#{pat}"
	action :start
	only_if { !pat.empty? }
end
