cmd = Mixlib::ShellOut.new("/opt/graphite/bin/carbon-relay.py status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
