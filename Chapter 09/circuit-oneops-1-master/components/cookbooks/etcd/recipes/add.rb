# Cookbook Name:: etcd
# Attributes:: add
#
# Author : OneOps
# Apache License, Version 2.0

# wire util library to chef resources.
extend Etcd::Util
Chef::Resource::RubyBlock.send(:include, Etcd::Util)

# check the compute platform
version = node.etcd.version
exit_with_err "Etcd #{version} is supported only on EL7 (RHEL/CentOS) or later." unless is_platform_supported?

# check if yum etcd package is available for installation.
# If not available, install by extracting the package file

if is_installed?('etcd', version)
  log "Already installed: #{version}"
else
  log 'Installing Etcd ...'
  if !is_pkg_avail?('etcd', version)
  
    # download the package from mirror location
    cookbook = node.app_name.downcase
    base_url, file_name = get_pkg_location(cookbook)
  
    binpath = "/tmp/#{file_name}"
    extract_path = node.etcd.extract_path
    
   Chef::Log.info("source url: #{base_url}/#{file_name}")
   
    remote_file binpath do
      owner 'root'
      group 'root'
      mode 0755
      source "#{base_url}/#{file_name}"
    end
  
    directory extract_path do
      recursive true
      action :delete
    end
  
    [node.etcd.working_location, node.etcd.conf_location, extract_path].each do |dir|
      directory "#{dir}" do
        user 'root'
        group 'root'
        mode 0755
      end
    end
  
    # untar the package
    bash "Untar #{file_name}" do
      cwd extract_path
      user 'root'
      group 'root'
      code "tar --overwrite -C #{extract_path} -xvf #{binpath} --strip-components=1"
      returns 0
    end
  
    # creating symlinks
    link '/usr/bin/etcd' do
      to '/opt/etcd/etcd'
    end
  
    link '/usr/bin/etcdctl' do
      to '/opt/etcd/etcdctl'
    end
  
  else
    # Package is available on OS yum repo.
    log 'package_install' do
      message "Installing the package Etcd-#{version} from OS yum repo..."
    end
  
    package 'etcd' do
      version version
      action :install
    end
  
  end
end

secure_command_args = ""
if node.etcd.security_enabled == 'true'
  secure_command_args = "--ca-file #{node.etcd.security_path}/ca.crt "
  secure_command_args += "--cert-file #{node.etcd.security_path}/server.crt "
  secure_command_args += "--key-file #{node.etcd.security_path}/server.key"      
end


# configure etcd flags
include_recipe 'etcd::configure'

# Setting the member ID
ruby_block 'replace old member_id' do
  block do
    if node.workorder.rfcCi.rfcAction == 'replace' && node.has_key?("peer_endpoints") && node.peer_endpoints.size >0
      cmd = "etcdctl #{secure_command_args} --endpoints=#{node.peer_endpoints.join(',')} "
      cmd += "member remove #{node.etcd.member_id}"
      Chef::Log.info(cmd)
      Chef::Log.info(`#{cmd}`)

      cmd = "etcdctl #{secure_command_args} --endpoints=#{node.peer_endpoints.join(',')} "
      cmd += "member add #{node.member_name} #{node.member_endpoint}"
      Chef::Log.info(cmd) 
      Chef::Log.info(`#{cmd}`)
    end
  end
end

# writing etcd systemd file
template node.etcd.systemd_file do
  source 'etcd.service.erb'
  mode 0644
end

# enable and start etcd service
execute 'systemctl daemon-reload'

# enable and start etcd service
service 'etcd' do
  action [:enable, :restart]
end

# Setting the member ID
ruby_block 'setting etcd member id' do
  block do

    retry_count = 1

    cname = node.workorder.payLoad.ManagedVia[0]['ciName']
    command = "etcdctl #{secure_command_args} member list | grep #{cname}"


    while retry_count < 10
      result=`#{command}`
      Chef::Log.info("Result output is: #{result}")
      message = result.empty? ? 'sleep' : 'success'

      if message == 'success'
        member_id=result.split(' ')[0].gsub(/[^0-9A-Za-z]/, '')
        puts "***RESULT:member_id=#{member_id}"
        break
      elsif message == 'sleep'
        Chef::Log.info("Unable to find etcd members. The result is: #{result}")
        Chef::Log.info("Maximum re-try count is set as 10. Sleeping for 10 seconds. Current re-try count is #{retry_count}")
        sleep 10
      end

      exit_with_err "#{command} is failed." if retry_count == 10
      retry_count += 1
    end
    action :create
  end
end

log 'Etcd installation completed!'
