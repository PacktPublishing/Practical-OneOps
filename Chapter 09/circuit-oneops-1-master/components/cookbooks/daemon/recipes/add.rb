#
# Cookbook Name:: daemon
# Recipe:: add
#
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

attrs = node.workorder.rfcCi.ciAttributes
service_name = attrs[:service_name]
# cannot use pattern in only_if or else will use the service's pattern attr
pat = attrs[:pattern] || ''

# init.d compliant control script / executable 
control_script_location = attrs[:control_script_location] || ''
control_script_content = attrs[:control_script_content] || ''

if !control_script_location.empty? && control_script_location != "/etc/init.d/#{service_name}"
  `ln -sf #{control_script_location} /etc/init.d/#{service_name}`
end

file "#{control_script_location}" do
  only_if { !control_script_content.empty? }
  owner "root"
  group "root"
  mode "0755"
  content "#{control_script_content}".gsub(/\r\n?/,"\n")
  action :create
end

# enable daemon service
service "#{service_name}" do
  action :enable
end

# restart daemon service when pattern has not been specified
ruby_block "restart #{service_name} service" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("service #{service_name} restart", :live_stream => Chef::Log::logger)
  end
  only_if { pat.empty? }
end

# restart daemon service when pattern has been specified
service "#{service_name}" do
  pattern "#{pat}"
  action :restart
  only_if { !pat.empty? }
end
