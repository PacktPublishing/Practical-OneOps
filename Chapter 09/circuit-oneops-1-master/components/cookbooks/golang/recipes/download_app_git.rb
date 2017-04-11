directory "#{node.workorder.rfcCi.ciAttributes.app_dir}/#{node.workorder.rfcCi.ciAttributes.app_version}" do
	recursive true
	owner "#{node.workorder.rfcCi.ciAttributes.app_user}"
	action :create
end

git "#{node.workorder.rfcCi.ciAttributes.app_dir}/#{node.workorder.rfcCi.ciAttributes.app_version}" do
	repository "#{node.workorder.rfcCi.ciAttributes.artifact_link}"
	revision "#{node.workorder.rfcCi.ciAttributes.artifact_git_revision}"
	action  :sync
	user "#{node.workorder.rfcCi.ciAttributes.app_user}"
end