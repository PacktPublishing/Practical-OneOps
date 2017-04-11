# Cookbook Name:: kubernetes
# Attributes:: add
#
# Author : OneOps
# Apache License, Version 2.0

# Wire util library to chef resources.
extend Kubernetes::Base
Chef::Resource::RubyBlock.send(:include, Kubernetes::Base)

# Check the platform
exit_with_err "Currently kubernetes is supported only on EL7 (RHEL/CentOS) or later." unless is_platform_supported?

# get etcd and kubelet servers - subtracting nodes from all to get masters until targetCiName filtering in payLoad
all_ips = []
node_ips = []
api_servers = []
node.workorder.payLoad['node-computes'].each do |ci|
  node_ips.push ci['ciAttributes']['private_ip']
end
node.workorder.payLoad['master-computes'].each do |ci|
  all_ips.push ci['ciAttributes']['private_ip']
end
master_ips = all_ips - node_ips
master_ips.each do |c|
  api_servers << "#{c}:8080"
end
node.set['kube']['kubelet']['api_servers'] = api_servers
node.set['kube']['kubelet']['machines'] = node_ips

etcd_servers = []
  
proto = "http"
if node.workorder.rfcCi.ciAttributes.etcd_security_enabled == 'true'
  proto = "https"
end
master_ips.each do |c|
  etcd_servers << "#{proto}://#{c}:2379"
end
node.set['etcd']['servers'] = etcd_servers.join(',')
  
if node.workorder.rfcCi.ciAttributes.security_enabled == 'true'
  `mkdir -p #{node.kubernetes.security_path}`
  File.open(node.kubernetes.security_path+'/ca.crt', 'w') { |file| file.write(node.kubernetes.security_ca_certificate) }
  File.open(node.kubernetes.security_path+'/server.crt', 'w') { |file| file.write(node.kubernetes.security_certificate) }
  File.open(node.kubernetes.security_path+'/server.key', 'w') { |file| file.write(node.kubernetes.security_key) }
  File.open(node.kubernetes.security_path+'/kubelet.crt', 'w') { |file| file.write(node.kubernetes.security_certificate) }
  File.open(node.kubernetes.security_path+'/kubelet.key', 'w') { |file| file.write(node.kubernetes.security_key) }    
end

if node.workorder.rfcCi.ciName.include?("-master")
  include_recipe "kubernetes::master"
else
  include_recipe "kubernetes::node"  
end

# move from default weekly rotate w/ 4 week retention to daily rotate 3 day retention
cookbook_file '/etc/logrotate.d/syslog' do
  source 'syslog.logrotate'
  owner 'root'
  group 'root'
  mode 0644
end

log 'Kubernetes install/update completed!'
