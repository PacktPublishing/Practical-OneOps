# Cookbook Name:: docker_engine
# Attributes:: add
#
# Author : OneOps
# Apache License, Version 2.0

# Wire util library to chef resources.
extend Docker::Util

Chef::Resource::RubyBlock.send(:include, Docker::Util)
Chef::Mixin::Template::TemplateContext.send(:include, Docker::Util)

docker_ver = node.docker_engine.version
docker_rel = node.docker_engine.release
docker_pkg = node.docker_engine.package
docker_svc = node.docker_engine.service

# Check the platform
exit_with_err "Currently #{docker_pkg} #{docker_ver} is supported only on EL7 (RHEL/CentOS) or later." unless is_platform_supported?

# Clean yum repo.
execute 'yum clean all' do
  user 'root'
  group 'root'
  action :nothing
end
       
# Configure the docker repo
template node.docker_engine.repo_file do
  source 'docker.repo.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :run, resources(:execute => 'yum clean all'), :immediately
end

include_recipe "docker_engine::network"

# Package is available on OS repo.
log 'package_install' do
  message "Installing the package #{docker_pkg}-#{docker_ver}-#{docker_rel} from OS repo..."
end

# install docker-engine-selinux first to avoid installing latest (1.13.0-1 - broken on centos7.2)
# use yum_package to allow downgrade
yum_package "docker-engine-selinux" do
  version "#{docker_ver}-#{docker_rel}"
  allow_downgrade true
  action :install
end

yum_package "#{docker_pkg}" do
  version "#{docker_ver}-#{docker_rel}"
  allow_downgrade true  
  action :install
end

# Stop docker engine before config changes.
service docker_svc do
  supports :status => true, :restart => true
  action :stop
end

# Installs docker remote API client
include_recipe 'docker_engine::add_docker_gem'

# Handle Docker TLS certs.
if node.docker_engine.tlsverify == 'true'
  file node.docker_engine.tlscacert_file do
    content node.docker_engine.tlscacert
    mode '0755'
    owner 'root'
    group 'root'
  end

  file node.docker_engine.tlscert_file do
    content node.docker_engine.tlscert
    mode '0755'
    owner 'root'
    group 'root'
  end

  file node.docker_engine.tlskey_file do
    content node.docker_engine.tlskey
    mode '0755'
    owner 'root'
    group 'root'
  end
end

# Systemd files
template "#{node.docker_engine.systemd_path}/docker.socket" do
  source 'docker.socket.erb'
  owner 'root'
  group 'root'
  mode 00644
end

template "#{node.docker_engine.systemd_path}/docker.service" do
  source 'docker.service.erb'
  owner 'root'
  group 'root'
  mode 00644
end


# Systemd docker drop-in file
directory node.docker_engine.systemd_drop_in_path do
  owner 'root'
  group 'root'
  recursive true
end

template "#{node.docker_engine.systemd_drop_in_path}/docker-options.conf" do
  source 'docker-options.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
end

# Systemd daemon reload.
execute 'systemctl daemon-reload' do
  user 'root'
  group 'root'
end

# Enable & Start docker engine.
service docker_svc do
  supports :status => true, :restart => true
  action [:enable, :restart]
end

ruby_block 'verify-docker' do
  block do
    init_docker_client
  end
end

# cleanup dangling images and exited containers
cookbook_file '/opt/oneops/docker-cleanup.sh' do
  source 'docker-cleanup.sh'
  owner 'root'
  group 'root'
  mode 0755
end

log 'Docker engine installation completed!'





