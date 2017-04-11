# Cookbook Name:: file
# Recipe:: default
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

windows_platform = node['platform_family'] == 'windows'

p = node.workorder.rfcCi.ciAttributes[:path]
c = node.workorder.rfcCi.ciAttributes[:content]
e = node.workorder.rfcCi.ciAttributes[:exec_cmd]

d = File.dirname(p)

directory "#{d}" do
  owner "root" unless windows_platform
  group "root" unless windows_platform
  mode "0755"
  recursive true
  action :create
  not_if { File.directory?(d) }
end

file "#{p}" do
  owner "root" unless windows_platform
  group "root" unless windows_platform
  mode "0755"
  content "#{c}".gsub(/\r\n?/,"\n")
  action :create
end

execute "#{e}" if ( e and !e.empty? )
