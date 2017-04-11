
node.cloud_ids.each do |id|
	file "/tmp/ssh/key_file_#{id}" do
		content node.workorder.payLoad.RequiresKeys.select { |k| k[:ciName].split("-")[1] == id }[0][:ciAttributes][:private]
		mode 0600
	end

	ruby_block "ghost modify" do
		block do
			Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
			ip_addresses = node.workorder.payLoad.RequiresComputes.select { |c| c[:ciName].split("-")[1] == id }
			ip_addresses.each do |ip|
				ssh_cmd = "ssh -i /tmp/ssh/key_file_#{id} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@#{ip[:ciAttributes][:private_ip]} "
				ghost_cmd = "ghost modify #{node.current_hostname} #{node.current_ip}"
				execute_cmd = shell_out("#{ssh_cmd} \"#{ghost_cmd}\"", :live_stream => Chef::Log)
				Chef::Log.info "#{execute_cmd.stdout}" unless "#{execute_cmd.stdout}".empty?
				Chef::Log.error "#{execute_cmd.stderr}" unless "#{execute_cmd.stderr}".empty?
			end
		end
	end
end
