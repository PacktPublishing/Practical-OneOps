directory "#{node.workorder.rfcCi.ciAttributes.app_dir}/#{node.workorder.rfcCi.ciAttributes.app_version}" do
	recursive true
	owner "#{node.workorder.rfcCi.ciAttributes.app_user}"
	action :create
end

_path = "#{node.workorder.rfcCi.ciAttributes.app_dir}/#{node.workorder.rfcCi.ciAttributes.app_version}"
_source = "#{node.workorder.rfcCi.ciAttributes.artifact_link}"

#shared_download_http "#{_source}" do
#  path _path
#  # action :nothing
#  checksum ''
#  basic_auth_user nil
#  basic_auth_password nil
#  action :create
#end


_filename = ::File.basename("#{_source}")

remote_file "#{_path}/#{_filename}" do
   source "#{_source}"
   owner "#{node.workorder.rfcCi.ciAttributes.app_user}"
   action :create
end

#execute "ls -l #{_path}"

case ::File.extname("#{_source}")
	when /gz|tgz|tar|bz2|tbz/
		execute "extract_artifact" do
			cwd "#{_path}"
			command "tar xf #{_filename} -C #{_path}"
			user "#{node.workorder.rfcCi.ciAttributes.app_user}"
			retries 2
		end
	when /zip|war|jar/
		execute "extract_artifact" do
			cwd "#{_path}"
			command "unzip -q -u -o #{_filename} -d #{_path}"
		end
end
