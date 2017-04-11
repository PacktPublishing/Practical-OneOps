kibana_version = node['kibana']['version']
Chef::Log.info("Kibana Version: #{kibana_version}")
install_path = node['kibana']['install_path']
Chef::Log.info("Kibana installation Path: #{install_path}")
arch = ( Gem::Version.new(kibana_version) < Gem::Version.new('4.5.10') ) ? 'linux-x64' : 'linux-x86_64'
current_path = "#{install_path}/kibana-#{kibana_version}-#{arch}/"
Chef::Log.info("Kibana Installation Location: #{current_path}")
cloud = node['workorder']['cloud']['ciName']

location = "#{node['kibana']['src_url']}/kibana-#{node['kibana']['version']}-#{arch}.tar.gz"

Chef::Log.info("Kibana Download location #{location} ")
Chef::Log.info("Kibana Version: #{kibana_version}")
Chef::Log.info("Kibana installation Path: #{install_path}")

tarball = "kibana-#{kibana_version}-#{arch}.tar.gz"
Chef::Log.info("Tar ball file name: #{tarball}")

tar_file_path = "#{install_path}/#{tarball}"
Chef::Log.info("Kibana Tar file Location: #{tar_file_path}")

#CREATE USER, group and Directoris
group node['kibana']['user'] do
  action :create
  system true
end

user node['kibana']['user'] do
  comment "Kibana User"
  home    node['kibana']['install_path']
  shell   "/bin/bash"
  gid     node['kibana']['user']
  supports :manage_home => false
  action  :create
  system true
end

directory node['kibana']['install_path'] do
  mode '0755'
  owner node['kibana']['user']
  group node['kibana']['group']
  recursive true
  action :create
end

remote_file "#{tar_file_path}" do
  source "#{location}"
  owner 'kibana'
  group 'kibana'
  mode '0775'
  #not_if { ::File.exists?(install_path) }
end

ruby_block "tar -xzf #{tar_file_path} -C #{install_path}" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("tar -xzf #{tar_file_path} -C #{install_path}",
               :user => 'kibana',
               :group => 'kibana',
               :live_stream => Chef::Log::logger)
	end
end


link '/app/kibana/current' do
    to "#{current_path}"
    owner node['kibana']['user']
    group node['kibana']['group']
end


template '/etc/init.d/kibana' do
  source 'upstart.conf.erb'
  mode '0755'
  notifies :restart, 'service[kibana]', :delayed
end

template "#{current_path}/config/kibana.yml" do
  source 'kibanaconfig.rb.erb'
  user node['kibana']['user']
  group node['kibana']['group']
  mode '0600'
  notifies :restart, 'service[kibana]', :delayed
end

service 'kibana' do
  action [:enable, :start]
end
