#
# Cookbook Name:: Sensuclient
# Recipe:: status
#
#
# 
cmd = Mixlib::ShellOut.new("/etc/init.d/sensu-client status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
