#
# Cookbook Name:: zookeeper
# Recipe:: default
#
#license          "Apache License, Version 2.0"
#
#

#Production cloud topology check for prod environments.
include_recipe "zookeeper::validate_config"

zk_basename = "zookeeper-#{node[:zookeeper][:version]}"
ci = node.workorder.rfcCi.ciAttributes;
zk_base_url = ci['mirror']
zk_download_location = "#{zk_base_url}"+"#{zk_basename}/"+"#{zk_basename}.tar.gz"

Chef::Log.info("download url from #{zk_download_location} ")

remote_file ::File.join(Chef::Config[:file_cache_path], "#{zk_basename}.tar.gz") do
  owner "root"
  mode "0644"
  source zk_download_location
  action :create
end


['install_dir' ,'log_dir', 'pid_dir','journal_dir','data_dir' ].each { |dir|
  dir_name = node[:zookeeper][dir]
  Chef::Log.info("creating #{dir} for users")
  directory dir_name do
    not_if { ::File.directory?(dir_name) }
    owner node[:zookeeper][:user]
    mode "0755"
    recursive true
  end
}
# create parent dir (keep ownership as root) if doesnt exist
# directory test_dir do
directory node[:zookeeper][:conf_dir] do
  action :create
end

unless ::File.exists?(::File.join(node[:zookeeper][:install_dir], zk_basename))

  execute 'install zookeeper' do
    user node[:zookeeper][:user]
    cwd Chef::Config[:file_cache_path]
    command "tar -C #{node[:zookeeper][:install_dir]} -zxf #{zk_basename}.tar.gz"
  end
end

include_recipe 'zookeeper::config_files'

is_zookeeper_running = system("service zookeeper-server status")
service "restart-zookeeper-server" do
  service_name "zookeeper-server"
  supports :status => true, :restart => true,:stop => true, :start => true
  %w[ zoo.cfg log4j.properties].each do |conf_file|
  subscribes :restart, resources("template[#{node[:zookeeper][:conf_dir]}/#{conf_file}]") , :delayed
  action [  :restart ]
  end
  
 # notifies :create, resources("ruby_block[zookeeper-server]"), :immediately
end if is_zookeeper_running

service "start-zookeeper-server" do
  service_name "zookeeper-server"
  action [ :enable, :start ]
  supports :status => true, :restart => true,:stop => true, :start => true

 # notifies :create, resources("ruby_block[zookeeper-server]"), :immediately
end

Chef::Log.info(node[:string_of_hostname])

Chef::Log.info("Copying monitoring script")
check_cluster_health = '/opt/nagios/libexec/check_cluster_health.sh'
template check_cluster_health do
  source "check_cluster_health.sh.erb"
  owner 'root'
  group 'root'
  mode "0755"
  #  action :create_if_missing
  variables({
                :string_of_ips => node[:string_of_hostname]                
            })
end
