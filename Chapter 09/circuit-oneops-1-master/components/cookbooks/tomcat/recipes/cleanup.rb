#
# Cookbook Name:: tomcat
# Recipe:: cleanup
#

major_and_minor_version = get_attribute_value("version")
build_version = get_attribute_value("build_version")
major_version = major_and_minor_version.gsub(/\..*/,"")
full_version = "#{major_and_minor_version}.#{build_version}"

tomcat_install_dir = get_attribute_value("tomcat_install_dir")
webapp_install_dir = get_attribute_value("webapp_install_dir")

install_type = get_attribute_value("install_type")
dest_file = "#{tomcat_install_dir}/apache-tomcat-#{full_version}.tar.gz"
service_script = "/etc/init.d/tomcat"+ major_version

Chef::Log.info("performing tomcat cleanup..")

case install_type
	when "binary"
		Chef::Log.info("removing symlink #{tomcat_install_dir}/tomcat#{major_version}")
		link "#{tomcat_install_dir}/tomcat#{major_version}" do
			action :delete
			only_if "test -L #{tomcat_install_dir}/tomcat#{major_version}"
		end

		Chef::Log.info("removing directory #{tomcat_install_dir}/apache-tomcat-#{full_version}")
		["#{tomcat_install_dir}/apache-tomcat-#{full_version}"].each do |dir|
			directory dir do
				recursive true
				action :delete
			end
		end

		Chef::Log.info("removing files #{dest_file} and #{service_script}")
		["#{dest_file}", "#{service_script}"].each  do |f|
			file f do
				action :delete
			end
		end
	when "repository"
		Chef::Log.info("removing package tomcat#{major_version}")
		package "tomcat#{major_version}" do
			action :remove
		end
end

Chef::Log.info("removing symlink #{webapp_install_dir}")
link webapp_install_dir do
	action :delete
	only_if "test -L #{webapp_install_dir}"
end

Chef::Log.info("removing "+Dir["#{webapp_install_dir}/*"].join(", "))
Dir["#{webapp_install_dir}/*"].each do |data|
	execute "rm -rf #{data}" do
		not_if { Dir["#{webapp_install_dir}/*"].empty? }
	end
end
