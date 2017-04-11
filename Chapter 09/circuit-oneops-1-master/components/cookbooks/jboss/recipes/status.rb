#
# Cookbook Name:: jboss
# Recipe:: status
#
cmd = Mixlib::ShellOut.new("service jboss status")
cmd.run_command
cmd.stdout
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
