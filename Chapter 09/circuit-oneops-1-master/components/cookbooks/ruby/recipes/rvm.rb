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

version = node[:ruby][:version]

package "libyaml"
execute "yum groupinstall -y 'development tools'"

# setup sources
cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]
if services.has_key?(:mirror)
  rvm = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])['rvm']
  rubies = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])['ruby']
end

if rvm && !rvm.empty?
  Chef::Log.info("Using cloud mirror for rvm install: #{rvm}")
else
  rvm = "https://github.com/wayneeseguin/rvm/tarball/stable"
end

if rubies && !rubies.empty?
  Chef::Log.info("Using cloud mirror for ruby install: #{rubies}")
else
  rubies = "https://rvm.io/binaries"
end

if node[:ruby].has_key?(:binary) && !node[:ruby][:binary].empty?
  ruby_binary = node[:ruby][:binary]
else
  case node[:platform]
  when "centos","redhat"
    ruby_platform = "centos"
    ruby_platform_version = node[:platform_version].to_i.to_s
  else
    ruby_platform = node[:platform]
    ruby_platform_version = node[:platform_version]
  end
  ruby_binary = "#{rubies}/#{ruby_platform}/#{ruby_platform_version}/#{node[:kernel][:machine]}/ruby-#{version}.tar.bz2"
end

Chef::Log.info("Installing rvm from #{rvm}")
Chef::Log.info("Installing ruby from #{ruby_binary}")

# download and install rvm
src_dir = "/usr/src"
dest_file = "rvm.tar.gz"
shared_download_http rvm do
  path "#{src_dir}/#{dest_file}"
  action :create
end

directory "#{src_dir}/rvm" do
  recursive true
  action :delete
end

directory "#{src_dir}/rvm" do
  recursive true
  action :create
end

execute "tar --strip-components=1 -xzf #{src_dir}/#{dest_file}" do
  cwd "#{src_dir}/rvm"
end

execute "./install --auto-dotfiles" do
  cwd "#{src_dir}/rvm"
end

# install ruby
bash "install ruby-#{version}" do
  code <<-EOH
source /etc/profile.d/rvm.sh
rvm mount -r #{ruby_binary} --verify-downloads 2
rvm use #{version} --default
EOH
end

# gems install
_gems = JSON.parse(node.workorder.rfcCi.ciAttributes.gems)
_gems.each do |gem,opts|

bash "#{gem}" do
    code <<-EOH
source /etc/profile.d/rvm.sh
rvm use #{version}
gem install #{gem} #{opts} --no-rdoc --no-ri
EOH
  end
end
