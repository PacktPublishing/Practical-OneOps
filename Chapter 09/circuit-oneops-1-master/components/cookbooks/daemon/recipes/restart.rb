#
# Cookbook Name:: daemon
# Recipe:: start
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

# restart daemon service when pattern has not been specified
ruby_block "restart #{service_name} service" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("service #{service_name} restart", :live_stream => Chef::Log::logger)
  end
  only_if { pat.empty? }
end

# restart daemon service when pattern has been specified
service "#{service_name}" do
  pattern "#{pat}"
  action :restart
  only_if { !pat.empty? }
end
