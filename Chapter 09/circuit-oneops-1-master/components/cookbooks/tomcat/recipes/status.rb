#
# Cookbook Name:: tomcat
# Recipe:: status
#
tomcat_service_name = tom_ver
jsw=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Javaservicewrapper/ }

if (!jsw.nil? && !jsw.empty?)
                include_recipe "javaservicewrapper::status"
else
	cmd = Mixlib::ShellOut.new("service #{tomcat_service_name} status")
	cmd.run_command
	#cmd.error!
	#Chef::Log.info(cmd.inspect)
	Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
end
