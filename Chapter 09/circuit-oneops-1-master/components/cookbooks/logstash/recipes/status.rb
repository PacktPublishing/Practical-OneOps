
_exec_cmd = "service logstash status"
ruby_block "#{_exec_cmd}" do
	block do
		Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
		shell_out!("#{_exec_cmd}", :live_stream => Chef::Log::logger)
    end
end