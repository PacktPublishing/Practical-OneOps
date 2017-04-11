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

Chef::Log.info("vagrant project #{vagrant_project}")
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

execute "destroy vm" do
  cwd vagrant_project
  command "vagrant destroy --force"
end

directory "#{vagrant_project}" do
  recursive true
  action :delete
end