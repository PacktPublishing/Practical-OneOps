#
# Cookbook Name:: nginx
# Recipe:: status
cmd = Mixlib::ShellOut.new("service nginx status")
cmd.run_command
if cmd.exitstatus == 0
  Chef::Log.info("Nginx service is running \n#{cmd.format_for_exception}")
else
  Chef::Log.info("Nginx service is NOT running \n#{cmd.format_for_exception}")
end
