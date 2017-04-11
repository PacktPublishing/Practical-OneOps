nodetool = "/opt/cassandra/bin/nodetool"
args = ::JSON.parse(node.workorder.arglist)
nodetool_command = args["nodetool_args"].to_s.strip
if nodetool_command.empty?
	nodetool_command = "status"
end
Chef::Log.info("nodetool_command : #{nodetool} #{nodetool_command}")
	
Nodetool::Util.validate(node.workorder.createdBy.to_s, nodetool_command)
ruby_block "execute_nodetool_command" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("#{nodetool} #{nodetool_command}", :live_stream => Chef::Log::logger)
     end
end