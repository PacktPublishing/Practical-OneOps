# encoding: UTF-8
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'kubernetes::firewall'
include_recipe 'kubernetes::go'

ci_index = node.workorder.rfcCi.ciName.split('-').last 

case node.kubernetes.network
when 'calico'
  
  include_recipe "kubernetes::calico"    
  
when 'flannel'

  # install flannel
  package 'flannel'
  template '/etc/sysconfig/flanneld' do
    source 'flanneld.erb'
  end    

  network_cidr = "11.11.0.0/16"
  if node.workorder.payLoad.has_key?("manifest-docker")
    docker = node.workorder.payLoad['manifest-docker'].first
    network_cidr = docker['ciAttributes']['network_cidr']
  end
      
  # returns 4 when already done
  flannel_conf = "{\"Network\": \"#{network_cidr}\", \"Backend\": {\"Type\": \"vxlan\", \"VNI\": 1}}"
  execute "etcdctl mk /docker-flannel/network/config '#{flannel_conf}'" do
      returns [0,4]
  end
  

  service 'flanneld' do
    action [:enable, :restart]
  end  
  
  if node.workorder.payLoad.has_key?("manifest-docker")
    docker = node.workorder.payLoad['manifest-docker'].first 
    if ci_index.to_i == 1    
      network_cidr = docker['ciAttributes']['network_cidr']
      Chef::Log.info("setting etcd flannel network: #{network_cidr}")
      
    end
  end

end


include_recipe 'kubernetes::install'

# generate kubernetes config files
%w(apiserver config controller-manager scheduler auth_policy token_auth_users basic_auth_users kubeconfig proxy).each do |file|
  template "/etc/kubernetes/#{file}" do
    cookbook 'kubernetes'
    source "#{file}.erb"
    owner 'root'
    group 'root'
    mode 00644
    action :create
  end
end

# generate systemd files
%w(kube-apiserver.service kube-controller-manager.service kube-scheduler.service kube-proxy.service).each do |service|
  cookbook_file "/usr/lib/systemd/system/#{service}" do
    source service
    mode 00644
    action :create
  end
end

execute "systemctl daemon-reload"

# define kubernetes master services
%w(kube-apiserver kube-controller-manager kube-scheduler kube-proxy).each do |service|
  service service do
    action [:enable, :restart]
  end
end

cookbook_file '/opt/nagios/libexec/check_nodes.rb' do
  source 'check_nodes.rb'
  mode 00755
  action :create
end

cookbook_file '/opt/nagios/libexec/check_pods.rb' do
  source 'check_pods.rb'
  mode 00755
  action :create
end


# master vip
if node.workorder.payLoad.has_key?('lbmaster')  
  lb_map = {}

  node.workorder.payLoad.lbmaster.each do |lb|
    next unless lb['ciName'].include?('lb-master')
    ci_name_parts = lb['ciName'].split('-')  
    ci_name_parts.pop
    cloud_id = ci_name_parts.pop
    lb_map[cloud_id] = lb['ciAttributes']['dns_record']
  end
  
  execute "etcdctl mk /kubernetes/contrib/vip_map '#{JSON.dump(lb_map)}'" do
    returns [0,4]
  end

  first_key = lb_map.keys.first
  master_vip = lb_map[first_key]
  execute "etcdctl mk /kubernetes/contrib/master_vip '#{master_vip}'" do
    returns [0,4]
  end    
  
end

# addons: dns and dashboard
files = %w(dns.yaml dashboard.yaml)
files.push 'calico-policy-controller.yaml' if node.kubernetes.network == 'calico'
files.each do |file|
  template "/etc/kubernetes/#{file}" do
    source "#{file}.erb"
    owner 'root'
    group 'root'
    mode 0644
  end
  # run only on the first master
  if ci_index.to_i == 1
    execute "kubectl create -f /etc/kubernetes/#{file}" do
      returns [0,1]
    end
  end

end
