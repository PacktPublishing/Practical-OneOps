execute "building Go App" do
	cwd "#{node.workorder.rfcCi.ciAttributes.app_dir}/#{node.workorder.rfcCi.ciAttributes.app_version}"
	user "#{node.workorder.rfcCi.ciAttributes.app_user}"
	command "chmod +x #{node.workorder.rfcCi.ciAttributes.source_name} && nohup ./#{node.workorder.rfcCi.ciAttributes.source_name} #{node.workorder.rfcCi.ciAttributes.app_cmdline_options} &"
end
