include_recipe "tomcat::stop"

#TODO needs refactoring
node.set['tomcat_owner'] = node['tomcat']['user']
node.set['tomcat_group'] = node['tomcat']['group']


if node['tomcat'].has_key?("tomcat_user") && !node['tomcat']['tomcat_user'].empty?
  node.set['tomcat_owner'] = node['tomcat']['tomcat_user']
end

version=node.tomcat.version.gsub(/\..*/,"")
Chef::Log.info("Starting to debug with user #{node.tomcat_owner}");


if File.exist?("#{node.tomcat.tomcat_install_dir}/tomcat#{version}/bin/catalina.sh")
  script "debug_tomcat" do
  interpreter "bash"
  user node[:tomcat][:tomcat_owner]
  cwd  "#{node.tomcat.tomcat_install_dir}/tomcat#{version}/bin/"
  code <<-EOH
     sudo -u "#{node.tomcat_owner}" ./catalina.sh jpda start
  EOH
  end
else
  Chef::Log.info("#{node.tomcat.tomcat_install_dir}/tomcat#{version}/bin/catalina.sh file does not exists.")
end
