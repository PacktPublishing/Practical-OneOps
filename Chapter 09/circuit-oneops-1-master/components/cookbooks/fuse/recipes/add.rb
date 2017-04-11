# Cookbook Name:: fuse
# Recipe:: default
#
# Copyright 2017, Vignesh Radhakrishnan
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


case node['fuse']['version']
when "6.0.0"    
  node['fuse']['url'] = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.0.0.redhat-098/jboss-fuse-full-6.0.0.redhat-098.zip"
  node['fuse']['filename'] = "jboss-fuse-full-6.0.0.redhat-098"
when "6.1.0"
  node['fuse']['url'] = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.1.0.redhat-401/jboss-fuse-full-6.1.0.redhat-401.zip"
  node['fuse']['filename'] = "jboss-fuse-full-6.1.0.redhat-401"
when "6.1.1"
  node['fuse']['url'] = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.1.1.redhat-472/jboss-fuse-full-6.1.1.redhat-472.zip"
  node['fuse']['filename'] = "jboss-fuse-full-6.1.1.redhat-472"
when "6.2.0"
  node['fuse']['url'] = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.2.0.redhat-123/jboss-fuse-full-6.2.0.redhat-123.zip"
  node['fuse']['filename'] = "jboss-fuse-full-6.2.0.redhat-123"
when "6.2.1"
  node['fuse']['url'] = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.2.1.redhat-177/jboss-fuse-full-6.2.1.redhat-177.zip"
  node['fuse']['filename'] = "jboss-fuse-full-6.2.1.redhat-177"
when "6.3.0"
  #node['fuse']['url'] = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.3.0.redhat-077/jboss-fuse-full-6.3.0.redhat-077.zip"
  url = "https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.3.0.redhat-077/jboss-fuse-full-6.3.0.redhat-077.zip"
  #node['fuse']['filename'] = "jboss-fuse-full-6.3.0.redhat-077"
  zipfilename = "jboss-fuse-full-6.3.0.redhat-077.zip"
  filename = "jboss-fuse-6.3.0.redhat-077"
end

execute 'Install fuse' do
  user 'root'
  command "rm -rf jbos* && wget -q #{url} && unzip #{zipfilename} -d #{node['fuse']['dir']} "
  action :run
  not_if { ::Dir.exists?("#{node['fuse']['dir']}/#{filename}")}
end

execute 'Starting fuse' do
  user 'root'
  cwd "#{node['fuse']['dir']}/#{filename}/bin" 
  command "cp -i start /etc/init.d && cp -i fuse /etc/init.d && chmod +x /etc/init.d/start && chmod +x /etc/init.d/fuse && ./start && nohup ./fuse >/dev/null 2>&1 &" 
  action :run
  not_if { ::Dir.exists?("#{node['fuse']['dir']}/#{filename}")}
end



Chef::Log.info "#{node['fuse']['url']}"
Chef::Log.info "#{filename} #{zipfilename}"
Chef::Log.info "#{node['fuse']['dir']}/#{filename}/bin"


execute "Maven setup" do
  user 'root'
  command <<-EOH
  rm -rf apache*
  wget -q http://redrockdigimark.com/apachemirror/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip
  unzip apache-maven-3.3.9-bin.zip -d #{node['fuse']['dir']}
  EOH
  not_if { ::Dir.exists?("#{node['fuse']['dir']}/apache-maven-3.3.9")}
end

template "#{node['fuse']['dir']}/#{filename}/etc/#{node['fuse']['users_properties']}" do
  source 'users.properties.erb'
  mode 0644
  variables(
    :app_user => node['fuse']['app']['user'],
    :app_password => node['fuse']['app']['password'],
    :app_role => node['fuse']['app']['role']
  )
end


template "/opt/setenv.sh" do
  source 'setenv.sh.erb'
  owner 'root'
  group 'root'
  mode "0755"
  variables(
    :java_home => node['fuse']['java_home'],
    :m2_home => node['fuse']['m2_dir']
  )
  action :create_if_missing
end 
execute "setting environment variables" do
   user 'root'
   cwd "opt"
   command <<-EOH
     source setenv.sh
     source ~/.bashrc
   EOH
   not_if {::File.exists?("/opt/setenv.sh")}
end
