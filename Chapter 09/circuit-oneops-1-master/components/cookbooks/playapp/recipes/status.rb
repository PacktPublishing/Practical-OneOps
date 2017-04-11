app_name=node.workorder.ci[:ciAttributes][:app_name]
cmd = Mixlib::ShellOut.new("/etc/init.d/#{app_name} status")
cmd.run_command
cmd.stdout
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
