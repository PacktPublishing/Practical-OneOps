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

include_recipe 'javaservicewrapper::wire_ci_attr'

#If the application name is being changed, we need to stop and cleanup earlier application
if node.workorder.rfcCi.ciBaseAttributes.has_key?("app_title") || node.workorder.rfcCi.ciBaseAttributes.has_key?("install_dir")
          old_app_title = node.workorder.rfcCi.ciAttributes.app_title
          if node.workorder.rfcCi.ciBaseAttributes.has_key?("app_title")
                old_app_title = node.workorder.rfcCi.ciBaseAttributes.app_title
          end
          old_install_dir = node.workorder.rfcCi.ciAttributes.install_dir
          if node.workorder.rfcCi.ciBaseAttributes.has_key?("install_dir")
              old_install_dir = node.workorder.rfcCi.ciBaseAttributes.install_dir
          end
        #remove the previsouly installed daemons if any
        if (File.exists?('/etc/init.d/' + old_app_title))
                puts "uninstalling app with old name: " + old_app_title
                service '#{old_app_title}' do
                        supports :status => false, :start => true, :stop => true, :restart => true
                        action [ :stop ]
                end

                bash 'uninstall_daemon' do
                        cwd "#{old_install_dir}/jsw/#{old_app_title}/bin"
                        code <<-EOH
                                ./uninstallDaemon.sh
                                rm -rf "#{old_install_dir}/jsw/#{old_app_title}"
                        EOH
                end
        end
end

# delete the jsw dir if already exists
directory "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}" do
  recursive true
  action :delete
end

#create the jsw and temp directory
directory "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/temp" do
  mode 00755
  owner node['javaservicewrapper']['as_user']
  group node['javaservicewrapper']['as_group']
  recursive true
  action :create
end

#download the jsw package
remote_file "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/temp/jsw.zip" do
  source "#{node['javaservicewrapper']['url']}"
  mode 00755
  owner "#{node['javaservicewrapper']['as_user']}"
  group "#{node['javaservicewrapper']['as_group']}"
end

#unzip the jsw package
bash 'extract_module' do
  cwd "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/temp"
  code <<-EOH
    unzip jsw*
    mv yajsw*/* ../
    EOH
end

#chmod for the shell scripts
bash 'chmod_bin' do
  cwd "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/bin"
  code <<-EOH
    		chmod 00755 *.sh 
	EOH
end


#delete the temp dir
directory "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/temp" do
  action :delete
end

if node['javaservicewrapper'].has_key?('working_dir') && !node['javaservicewrapper']['working_dir'].empty?
  include_recipe "javaservicewrapper::stop"
  include_recipe "javaservicewrapper::configure"
  include_recipe "javaservicewrapper::start"
end

