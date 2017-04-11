include_recipe 'javaservicewrapper::wire_ci_attr'

cmd = Mixlib::ShellOut.new("/etc/init.d/#{node["javaservicewrapper"]["app_title"]} status")
        cmd.run_command
        #cmd.error!
        #Chef::Log.info(cmd.inspect)
        Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
