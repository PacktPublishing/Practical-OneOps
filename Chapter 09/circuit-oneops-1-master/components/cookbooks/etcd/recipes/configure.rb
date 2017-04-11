# Cookbook Name:: etcd
# Attributes:: configure
#
# Author : OneOps
# Apache License, Version 2.0

# Get all the required computes
require 'uri'
require 'net/http'

# wire util library to chef resources.
extend Etcd::Util
Chef::Resource::RubyBlock.send(:include, Etcd::Util)

platform_level_fqdn = true

if node.workorder.payLoad.has_key?(:computes)
  computes = node.workorder.payLoad.computes
else
  computes = node.workorder.payLoad.RequiresComputes
end

local_server_ip =  node.workorder.payLoad.ManagedVia[0]['ciAttributes']['private_ip']
# `local_server_ip` is updated with the full hostname only if `etcd` depends on hostname component
local_server_ip =  get_full_hostname(node[:ipaddress]) if depend_on_hostname_ptr?
local_server_name = node.workorder.payLoad.ManagedVia[0]['ciName']

primary_cloud = false

if node.workorder.cloud.ciAttributes.has_key?("priority") &&
    node.workorder.cloud.ciAttributes.priority == "1"
  primary_cloud = true
end

Chef::Log.info("rfcAction: #{node.workorder.rfcCi.rfcAction}")

etcd_cluster = Array.new
peer_endpoints = Array.new
# Get etcd members

protocol = "http"
if node.etcd.security_enabled == 'true'
  protocol = "https"
end

if primary_cloud == true
  Chef::Log.info("In primary clouds")
  if depend_on_hostname_ptr?
    platform_fqdn = get_fqdn(node[:ipaddress], platform_level_fqdn)
    # query platform-level fqdn for the computes in primary clouds
    primary_computes_ips = `host #{platform_fqdn} | awk '{ print $NF }'`.split("\n")
    # if there are computes from secondary clouds
    if primary_computes_ips.length < computes.length
      primary_computes = Array.new
      # filter out the compute instances in secondary clouds from `computes`
      computes.each do |c, index|
        if c.ciAttributes.has_key?("private_ip") && c.ciAttributes.private_ip != nil &&
            primary_computes_ips.include?(c.ciAttributes.private_ip)
          primary_computes.push(c)
        end
      end
      computes = primary_computes
    end
  end
  
  managed_via_compute = node.workorder.payLoad.ManagedVia.first
  
  computes.each do |c, index|
    if c.ciAttributes.has_key?("private_ip") && c.ciAttributes.private_ip != nil
      if depend_on_hostname_ptr?
        full_hostname = get_full_hostname(c.ciAttributes.private_ip)
        etcd_cluster.push("#{c.ciName}=#{protocol}://#{full_hostname}:2380")
      else
        etcd_cluster.push("#{c.ciName}=#{protocol}://#{c.ciAttributes.private_ip}:2380")        
      end
      if c.ciAttributes.private_ip != managed_via_compute['ciAttributes']['private_ip']
        peer_endpoints.push("#{protocol}://#{c.ciAttributes.private_ip}:2379")        
      else
        node.set['member_name'] = c.ciName
        node.set['member_endpoint'] = "#{protocol}://#{c.ciAttributes.private_ip}:2380"
      end
    end
  end
  node.set['peer_endpoints'] = peer_endpoints
    
else

# Assume that the nodes from secondary clouds will form a new Etcd cluster, which is
# independent of the Etcd cluster in primary clouds.

# The goal of the following method is to identify which IPs belong to secondary clouds.
# It assumes:
# (1) Etcd component has to depend on "hostname" component with PTR enabled.
# (2) no LB is used. Otherwise, querying FQDN (host `fqnd`) will return the IPs of LB

# By querying the platform-level fqdn, we could know the computes from the primary clouds.
# After removing the returned IPs from workorder.PayLoad.computes, the remaining IPs should
# belong to secondary clouds.

  Chef::Log.info("secondary clouds...")
  platform_fqdn = get_fqdn(node[:ipaddress], platform_level_fqdn)
  primary_computes_ips = `host #{platform_fqdn} | awk '{ print $NF }'`.split("\n")
  Chef::Log.info("primary_computes_ips: #{primary_computes_ips.to_s}")
  
  computes.each do |c, index|
    if c.ciAttributes.has_key?("private_ip") && !primary_computes_ips.include?(c.ciAttributes.private_ip)
      Chef::Log.info("c.ciAttributes.private_ip: #{c.ciAttributes.private_ip}")
      if depend_on_hostname_ptr?
        hostname = get_full_hostname(c.ciAttributes.private_ip)
        etcd_cluster.push("#{c.ciName}=#{protocol}://#{hostname}:2380")
      else
        etcd_cluster.push("#{c.ciName}=#{protocol}://#{c.ciAttributes.private_ip}:2380")
      end
    end
  end
  
end


if node.etcd.security_enabled == 'true'
  exit_with_err 'server security certificate is empty.' if node.etcd.security_certificate.empty?
  exit_with_err 'server security key is empty.' if node.etcd.security_key.empty?
  exit_with_err 'certificate authority CA certificate is empty.' if node.etcd.security_ca_certificate.empty?

  directory node.etcd.security_path

  file "#{node.etcd.security_path}/server.crt" do
    content node.etcd.security_certificate
    mode '0644'
  end
  file "#{node.etcd.security_path}/server.key" do
    content node.etcd.security_key
    mode '0644'
  end

  file "#{node.etcd.security_path}/ca.crt" do
    content node.etcd.security_ca_certificate
    mode '0644'
  end

  security_flags = {
      'ETCD_PEER_CERT_FILE' => "#{node.etcd.security_path}/server.crt",
      'ETCD_PEER_KEY_FILE' => "#{node.etcd.security_path}/server.key",
      'ETCD_PEER_TRUSTED_CA_FILE' => "#{node.etcd.security_path}/ca.crt",
      'ETCD_CERT_FILE' => "#{node.etcd.security_path}/server.crt",
      'ETCD_KEY_FILE' => "#{node.etcd.security_path}/server.key",
      'ETCD_TRUSTED_CA_FILE' => "#{node.etcd.security_path}/ca.crt",

      'ETCD_CLIENT_CERT_AUTH' => 'true'
  }.merge(JSON.parse(node.etcd.security_flags))

elsif node.etcd.security_enabled == 'false'
  security_flags = {
  }.merge(JSON.parse(node.etcd.security_flags))
end

# Update default configuration with parameters passed by user in oneops design
member_flags = {
    'ETCD_NAME' => local_server_name,
    'ETCD_DATA_DIR' => "/var/lib/etcd/#{local_server_name}.etcd",
    'ETCD_SNAPSHOT_COUNT' => '10000',
    'ETCD_HEARTBEAT_INTERVAL' => '100',
    'ETCD_ELECTION_TIMEOUT' => '1000',
    'ETCD_LISTEN_PEER_URLS' => "#{protocol}://#{local_server_ip}:2380",
    'ETCD_LISTEN_CLIENT_URLS' => "#{protocol}://#{local_server_ip}:2379,#{protocol}://127.0.0.1:2379",
    'ETCD_MAX_SNAPSHOTS' => '5',
    'ETCD_MAX_WALS' => '5',
    'ETCD_CORS' => 'none'
}.merge(JSON.parse(node.etcd.member_flags))

etcd_initial_cluster_token = primary_cloud ? 'etcd-cluster-1' : 'etcd-cluster-2'

# migrate data dir
data_dir = member_flags['ETCD_DATA_DIR']
volumes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Volume/ }
if volumes.size > 0 && !File.symlink?(data_dir)
  volume = volumes.first
  mount_point =  volume['ciAttributes']['mount_point']
  Chef::Log.info("moving data dir #{data_dir} to #{mount_point}")

  service 'etcd' do
    action :stop
  end
  execute "mv #{data_dir}/* #{mount_point}" do
    returns [0,1]
  end
  execute "rm -fr #{data_dir}"
  execute "ln -s #{mount_point} #{data_dir}"
end

etcd_initial_cluster_state = "new"
if node.workorder.rfcCi.rfcAction == "replace"
  etcd_initial_cluster_state = "existing"
elsif node.workorder.rfcCi.rfcAction == "update"
  # continue to use the original state
  etcd_initial_cluster_state = `cat /etc/etcd/etcd.conf | grep ETCD_INITIAL_CLUSTER_STATE | tr "=" "\n" | tail -n 1 | tr -d '"'`.strip
  if etcd_initial_cluster_state.empty?
     etcd_initial_cluster_state = "new"
  end
end

cluster_flags = {
    'ETCD_INITIAL_ADVERTISE_PEER_URLS' => "#{protocol}://#{local_server_ip}:2380",
    'ETCD_INITIAL_CLUSTER' => "#{etcd_cluster.join(",")}",
    'ETCD_INITIAL_CLUSTER_STATE' => etcd_initial_cluster_state,
    'ETCD_INITIAL_CLUSTER_TOKEN' => etcd_initial_cluster_token,
    'ETCD_ADVERTISE_CLIENT_URLS' => "#{protocol}://#{local_server_ip}:2379"
}.merge(JSON.parse(node.etcd.cluster_flags))

proxy_flags = {
    'ETCD_PROXY' => 'off',
    'ETCD_PROXY_FAILURE_WAIT' => '5000',
    'ETCD_PROXY_REFRESH_INTERVAL' => '30000',
    'ETCD_PROXY_DIAL_TIMEOUT' => '1000',
    'ETCD_PROXY_WRITE_TIMEOUT' => '5000',
    'ETCD_PROXY_READ_TIMEOUT' => '0'
}.merge(JSON.parse(node.etcd.proxy_flags))

logging_flags = {
    'ETCD_DEBUG' => 'false',
    'ETCD_LOG_PACKAGE_LEVELS' => 'none'
}.merge(JSON.parse(node.etcd.logging_flags))

unsafe_flags = {
    'ETCD_FORCE_NEW_CLUSTER' => 'false'
}.merge(JSON.parse(node.etcd.unsafe_flags))

experimental_flags = {
    'ETCD_EXPERIMENTAL_V3DEMO' => 'false'
}.merge(JSON.parse(node.etcd.experimental_flags))

miscellaneous_flags = {
    'ETCD_VERSION' => 'false'
}.merge(JSON.parse(node.etcd.miscellaneous_flags))

profiling_flags = {
    'ETCD_ENABLE_PPROF' => 'false'
}.merge(JSON.parse(node.etcd.profiling_flags))

# setting all configuation flags to the node
node.set['etcd']['member'] = member_flags
node.set['etcd']['cluster'] = cluster_flags
node.set['etcd']['proxy'] = proxy_flags
node.set['etcd']['security'] = security_flags
node.set['etcd']['logging'] = logging_flags
node.set['etcd']['unsafe'] = unsafe_flags
node.set['etcd']['experimental'] = experimental_flags
node.set['etcd']['miscellaneous'] = miscellaneous_flags
node.set['etcd']['profiling'] = profiling_flags

# writing etcd config file
template node.etcd.conf_file do
  source 'etcd.conf.erb'
  mode 0644
  variables({
                :member_flags => node.etcd.member,
                :cluster_flags => node.etcd.cluster,
                :proxy_flags => node.etcd.proxy,
                :security_flags => node.etcd.security,
                :logging_flags => node.etcd.logging,
                :unsafe_flags => node.etcd.unsafe,
                :experimental_flags => node.etcd.experimental,
                :miscellaneous_flags => node.etcd.miscellaneous,
                :profiling_flags => node.etcd.profiling
            })
end
