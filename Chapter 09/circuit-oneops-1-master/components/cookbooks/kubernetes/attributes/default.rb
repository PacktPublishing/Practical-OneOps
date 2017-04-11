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


# kubernetes master
default['kube']['api']['host'] = ''
default['kube']['api']['bind-address'] = '0.0.0.0'
default['kube']['api']['bind-port'] = node.kubernetes.api_port
default['kube']['api']['bind-port-secure'] = node.kubernetes.api_port_secure

default['kube']['service']['addresses'] = node.kubernetes.service_addresses
default['kube']['scheduler']['args'] = ''

controller_manager_args_value = ''
if node.kubernetes.has_key?("controller_manager_args")
  args = JSON.parse(node.kubernetes.controller_manager_args)
  args.each_pair do |k,v|
    Chef::Log.info("setting controller_manager arg: --#{k}=#{v}")
    controller_manager_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['controller-manager']['args'] = controller_manager_args_value.strip
  
scheduler_args_value = ''
if node.kubernetes.has_key?("scheduler_args")
  args = JSON.parse(node.kubernetes.scheduler_args)
  args.each_pair do |k,v|
    Chef::Log.info("setting scheduler arg: --#{k}=#{v}")
    scheduler_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['scheduler']['args'] = scheduler_args_value.strip

api_args_value = ''
if node.kubernetes.has_key?("api_args")
  args = JSON.parse(node.kubernetes.api_args)
  args.each_pair do |k,v|
    Chef::Log.info("setting api arg: --#{k}=#{v}")
    api_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['api']['args'] = api_args_value.strip   
  
# kubernetes nodes
default['kube']['kubelet']['machines'] = []
default['kube']['kubelet']['bind-address'] = '0.0.0.0'
default['kube']['kubelet']['bind-port'] = '10250'
  
kubelet_args_value = ''
if node.kubernetes.has_key?("kubelet_args")
  kubelet_args = JSON.parse(node.kubernetes.kubelet_args)
  kubelet_args.each_pair do |k,v|
    Chef::Log.info("setting kubelet arg: --#{k}=#{v}")
    kubelet_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['kubelet']['args'] = kubelet_args_value.strip
  
proxy_args_value = ''
if node.kubernetes.has_key?("proxy_args")
  proxy_args = JSON.parse(node.kubernetes.proxy_args)
  proxy_args.each_pair do |k,v|
    Chef::Log.info("setting proxy arg: --#{k}=#{v}")
    proxy_args_value += " --#{k}=#{v}"
  end
end
node.set['kube']['proxy']['args'] = proxy_args_value.strip
  
  
default['kube']['interface'] = 'eth0'


# related packages
default['kube']['go']['package'] = 'golang'
