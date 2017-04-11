#
# calico kubernetes integration
# 

# shutdown flannel
# TODO: factor to netcleanup recipe
if File.exists?('/etc/sysconfig/flanneld')
  service 'flanneld' do
    action [:disable, :stop]
  end
end

template "/usr/lib/systemd/system/calico-node.service" do
  source "calico-node.service.erb"
  owner 'root'
  group 'root'
  mode 0644
end

directory "/opt/cni/bin" do
  recursive true
end

cni_mirror = "https://github.com/containernetworking"

cloud_name = node.workorder.cloud.ciName
if node.workorder.services.has_key?("mirror") &&
   node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'].include?('kubernetes')
  
  mirrors = JSON.parse(node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'])
  if mirrors.has_key?("kubernetes")
    cni_mirror = mirrors['kubernetes'] + '/kubernetes'
    Chef::Log.info("using mirror: #{cni_mirror}")
  end
  
end


cni_loopback_version = "0.3.0"
cni_loopback_tgzfile = "cni-v#{cni_loopback_version}.tgz"  
cni_loopback_url = cni_mirror + "/cni/releases/download/v#{cni_loopback_version}/#{cni_loopback_tgzfile}"

remote_file "/opt/cni/#{cni_loopback_tgzfile}" do
  source cni_loopback_url
  owner 'root'
  group 'root'
  mode '0644'
end

execute "tar -zxf #{cni_loopback_tgzfile} ; cp loopback bin/" do
  cwd '/opt/cni'
end


calico_mirror = "https://github.com/projectcalico/calico-cni"
if node.workorder.services.has_key?("mirror") &&
   node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'].include?('kubernetes')
  
  mirrors = JSON.parse(node.workorder.services.mirror[cloud_name]['ciAttributes']['mirrors'])
  if mirrors.has_key?("kubernetes")
    calico_mirror = mirrors['kubernetes'] + '/kubernetes'   
    Chef::Log.info("using mirror: #{cni_mirror}")
  end
  
end

calico_cni_version = "1.5.5"
%w(calico calico-ipam calicoctl).each do |file|
  url = calico_mirror + "/cni-plugin/releases/download/v#{calico_cni_version}/#{file}"
  remote_file "/opt/cni/bin/#{file}" do
    source url
    owner 'root'
    group 'root'
    mode '0755'
  end
end


template "/opt/cni/pool.conf" do
  source "calico-pool.conf.erb"
  owner 'root'
  group 'root'
  mode 0644
end

execute "/opt/cni/bin/calicoctl create -f /opt/cni/pool.conf" do
  environment 'ETCD_ENDPOINTS' => node['etcd']['servers']
  returns [0,1]
end

directory "/etc/cni/net.d" do
  recursive true
end

template "/etc/cni/net.d/calico-kubeconfig" do
  source "kubeconfig.erb"
  owner 'root'
  group 'root'
  mode 0644
end

template "/etc/cni/net.d/10-calico.conf" do
  source "calico.conf.erb"
  owner 'root'
  group 'root'
  mode 0644
end

execute "systemctl daemon-reload"

service 'calico-node' do
  action [:enable, :restart]
end
