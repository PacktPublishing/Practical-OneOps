cmd = Mixlib::ShellOut.new("/etc/init.d/#{service governor status")
cmd.run_command
#cmd.error!
#Chef::Log.info(cmd.inspect)
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
