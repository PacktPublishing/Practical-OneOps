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
include_recipe 'kubernetes::install'

package "conntrack"

case node.kubernetes.network
when 'calico'  
  include_recipe "kubernetes::calico" 
end

# generate kubernetes config file
%w(config kubelet proxy kubeconfig).each do |file|
  template "/etc/kubernetes/#{file}" do
    cookbook 'kubernetes'
    source "#{file}.erb"
    owner 'root'
    group 'root'
    mode 00644
    action :create
  end
end

# generate systemd file
%w(kube-proxy.service kubelet.service).each do |service|
  cookbook_file "/usr/lib/systemd/system/#{service}" do
    source service
    mode 00644
    action :create
  end
end

execute "systemctl daemon-reload"

# define kubernetes master services
%w(kubelet kube-proxy).each do |service| 
  service service do
    action [:enable, :restart]
  end
end
