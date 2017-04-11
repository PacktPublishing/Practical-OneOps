#
# Cookbook Name:: tomcat
# Recipe:: start
#

tomcat_service_name = tom_ver
depends_on=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Javaservicewrapper/ }

if (!depends_on.nil? && !depends_on.empty?)
	        include_recipe "javaservicewrapper::start"
else
  ruby_block "Start tomcat service" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service #{tomcat_service_name} start ",
                 :live_stream => Chef::Log::logger)
    end
  end
end
