# Cookbook Name:: activemq
# Recipe:: stop
#

unless ::File.exists?("/etc/init.d/activemq")
 return true
end
cmd = Mixlib::ShellOut.new("/etc/init.d/activemq stop")
cmd.run_command
sleep 5
cmdstatus = Mixlib::ShellOut.new("/etc/init.d/activemq status")
cmdstatus.run_command

if cmdstatus.stdout.include?"ActiveMQ Broker is running."
  Chef::Application.fatal!("Exiting because exit code from activemq is: #{cmdstatus.exitstatus}")
end

