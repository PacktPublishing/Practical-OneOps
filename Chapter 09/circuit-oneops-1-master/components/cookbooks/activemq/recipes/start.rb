# Cookbook Name:: activemq
# Recipe:: start
#

cmd = Mixlib::ShellOut.new("/etc/init.d/activemq start")
cmd.run_command
sleep 5
cmdstatus = Mixlib::ShellOut.new("/etc/init.d/activemq status")
cmdstatus.run_command

if cmdstatus.stdout.include? "ActiveMQ Broker is not running."
  Chef::Application.fatal!("Exiting because exit code from activemq is: #{cmdstatus.exitstatus}")
end
