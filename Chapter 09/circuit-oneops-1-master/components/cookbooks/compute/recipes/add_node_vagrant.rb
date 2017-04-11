# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

rfcCi = node[:workorder][:rfcCi]

cloud_name = node[:workorder][:cloud][:ciName]
cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]


vagrant_home = File.expand_path(cloud[:path])
vagrant_project = "#{vagrant_home}/#{node[:server_name]}"


node.set[:vm_cpu], node.set[:vm_memory] = node[:size_id].split("x")

Chef::Log.info("vagrant project #{vagrant_project}")
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

directory "#{vagrant_home}" do
  mode "0755"
  action :create
end

directory "#{vagrant_project}" do
  mode "0755"
  action :create
end

template "#{vagrant_project}/Vagrantfile" do
  source "Vagrantfile.erb"
  mode 0644
end

template "#{vagrant_project}/setup.sh" do
  source "setup.sh.erb"
  mode 0755
end

file "public_key" do
  path "#{vagrant_project}/authorized_keys"
  mode 0644
  content node.workorder.payLoad.SecuredBy[0][:ciAttributes][:public]
end

directory "#{vagrant_project}/share"

# virtualbox has issues with parallel adds - stagger by ciName index
ci_index = node.workorder.rfcCi.ciName[-1,1].to_i
execute "sleep #{60*(ci_index-1)}" do
    not_if { ci_index == 1 }
end

execute "start vm" do
  cwd vagrant_project
  command "vagrant up"
end

execute "retrieve_ip_address" do
  cwd vagrant_project
  command "vagrant ssh -c 'ifconfig eth1' | grep inet | awk '{ print $2 }' | head -1 | sed 's/addr://' > ip_address"
end


# output
ruby_block "start vm" do
  block do    
    private_ip = `cd #{vagrant_project} && cat ip_address`.chomp
    Chef::Log.info("private_ip: "+private_ip)    
    puts "***RESULT:private_ip="+ private_ip    
    puts "***RESULT:instance_id="+ node[:server_name]    
  end
end
