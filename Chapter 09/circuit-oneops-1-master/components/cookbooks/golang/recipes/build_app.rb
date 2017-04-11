execute "building Go App" do
	cwd "#{node.workorder.rfcCi.ciAttributes.app_dir}/#{node.workorder.rfcCi.ciAttributes.app_version}"
	user "#{node.workorder.rfcCi.ciAttributes.app_user}"
	command "#{node.workorder.rfcCi.ciAttributes.go_install_dir}/go/bin/go get ./... && nohup #{node.workorder.rfcCi.ciAttributes.go_install_dir}/go/bin/go run #{node.workorder.rfcCi.ciAttributes.source_name}.go #{node.workorder.rfcCi.ciAttributes.app_cmdline_options} &"
end
