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

ci = nil
# work order
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
# action order
elsif node.workorder.has_key?("ci")
  ci = node.workorder.ci
end
vars = JSON.parse(ci[:ciAttributes][:variables]) || {}

cron "#{ci[:ciBaseAttributes][:user]} #{ci[:ciName]}" do
  user ci[:ciBaseAttributes][:user]
  action :delete
  only_if { ci[:ciBaseAttributes].to_hash.has_key?('user') }
end

cron "#{ci[:ciAttributes][:user]} #{ci[:ciName]}" do
  minute ci[:ciAttributes][:minute]
  hour ci[:ciAttributes][:hour]
  day ci[:ciAttributes][:day]
  month ci[:ciAttributes][:month]
  weekday ci[:ciAttributes][:weekday]
  command ci[:ciAttributes][:cmd]
  user ci[:ciAttributes][:user]
  home vars['HOME'] if vars.has_key?('HOME') && !vars['HOME'].empty?
  shell vars['SHELL'] if vars.has_key?('SHELL') && !vars['SHELL'].empty?
  mailto vars['MAILTO'] if vars.has_key?('MAILTO') && !vars['MAILTO'].empty?
  # workaround to reset mailto in multi-job/cron case
  # https://tickets.opscode.com/browse/CHEF-1670
  mailto '""' if vars['MAILTO'].empty?    
  path vars['PATH'] if vars.has_key?('PATH') && !vars['PATH'].empty?
  action :create
end
