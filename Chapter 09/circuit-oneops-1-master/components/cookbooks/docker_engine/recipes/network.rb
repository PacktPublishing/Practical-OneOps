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

package "bridge-utils"

case node.docker_engine.network
when 'flannel'
  # remove openvswitch
  package "openvswitch" do
    action :remove
  end
  execute "rm -rf /etc/sysconfig/network-scripts/kbr0 ; ip link delete kbr0 ; true"

  # install flannel
  package 'flannel'
  template '/etc/sysconfig/flanneld' do
    source 'flanneld.erb'
  end

  service 'flanneld' do
    action [:enable, :restart]
  end    
 
  
when 'openvswitch'  

  kbr0_ip_prefix = '172.17.'
  ip_address = address_for(node['kube']['interface'])
  
  # install openvswitch package
  # TODO: put on mirror or cleanup/release after 2.5 is on epel
  execute "wget -P /tmp http://10.65.160.69/release/openvswitch-2.5.0-1.x86_64.rpm"
  execute "yum -y localinstall /tmp/openvswitch-2.5.0-1.x86_64.rpm"
  package "bridge-utils"
  
  # start openvswitch service
  service 'openvswitch' do
    action [:enable, :start]
  end
  
  # create ovs bridge obr0
  execute 'ovs-vsctl br-exists obr0 || ovs-vsctl add-br obr0'
  
  # get minion ip addresses and index: {'ip_address' => index}
  minion_hash = {}
  node['kube']['kubelet']['machines'].each_index do |index|
    ip = node['kube']['kubelet']['machines'][index]
    minion_hash[ip] = index
  end
  
  # create ovs gre tunnel
  minion_hash.each { |peer_ip, index|
    port = "gre#{index}"
    next if peer_ip == ip_address
    execute "ovs-vsctl port-to-br #{port} || ovs-vsctl add-port obr0 #{port} -- set Interface #{port} type=gre options:remote_ip=#{peer_ip}"
  }
  
  # create kuber bridge
  execute 'brctl addbr kbr0 || :'
  
  # make obr0 a port of kbr0
  execute 'brctl addif kbr0 obr0 || :'
  
  # find the index of this node's ip_address in machines list
  index = minion_hash[ip_address]
  # set the ip address of kbr0 to 172.17.INDEX.1
  kbr_ip = "#{kbr0_ip_prefix}#{index}.1"
  # persistent kbr0
  template '/etc/sysconfig/network-scripts/ifcfg-kbr0' do
    cookbook 'kubernetes'
    source 'ifcfg-kbr0.erb'
    owner 'root'
    group 'root'
    mode 00644
    variables(
      ip_address: kbr_ip
    )
  end
  
  # make kbr0 active
  execute 'ifup kbr0'
  
  
  # create router file for kbr0 on kubernetes service interface
  content = ''
  minion_hash.each { |peer_ip, index|
    next if peer_ip == ip_address
    content << "#{kbr0_ip_prefix}#{index}.0/24 via #{peer_ip}\n"
  }
  file "/etc/sysconfig/network-scripts/route-#{node['kube']['interface']}" do
    owner 'root'
    group 'root'
    mode 00644
    content content
  end
  
  # make the routes active
  result = `ifconfig #{node['kube']['interface']} | head | grep UP`
  if $?.to_i != 0
    execute "ifup #{node['kube']['interface']}"  
  end

end
