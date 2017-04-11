#
# Cookbook Name:: nfs
# Recipe:: exports
#
# Copyright 2011, Eric G. Wolfe
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
#

execute "exportfs" do
  command "exportfs -ar"
  action :nothing
end

_exports = JSON.parse(node.workorder.rfcCi.ciAttributes.exports)

unless _exports.empty?
  _exports.keys.each do |_dir|
    directory "#{_dir}" do
      recursive true
      mode 0777
      action :create
    end
  end  
  file "/etc/exports" do
     mode 0644
     content _exports.to_a.collect { |v| v.join(" ") }.join("\n")
     notifies :run, "execute[exportfs]"
  end
end
