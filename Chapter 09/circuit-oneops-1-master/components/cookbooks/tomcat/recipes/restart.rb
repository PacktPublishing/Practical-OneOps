#
# Cookbook Name:: tomcat
# Recipe:: restart
#
tomcat_service_name = tom_ver
depends_on=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Javaservicewrapper/ }

if (!depends_on.nil? && !depends_on.empty?)
  include_recipe "javaservicewrapper::restart"
else
 ruby_block "Restart tomcat service" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service #{tomcat_service_name} restart ",
                 :live_stream => Chef::Log::logger)
    end
  end

end
