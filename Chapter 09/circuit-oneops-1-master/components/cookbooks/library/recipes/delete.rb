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

# Cookbook Name:: library
# Recipe:: add
#


_packages = JSON.parse(node.workorder.rfcCi.ciAttributes.packages)
_packages.each do |package_list|
  package_list.split(/[,\s]+/).each do |package|

    pkgdata = package.split(':')
    
    name = pkgdata.pop
    platform = pkgdata.pop
    
    if platform && platform != node[:platform]
      Chef::Log.info("Skipping package #{name} because package filter #{platform} does not match current node platform #{node[:platform]}")
      next
    end
    
    if name.empty?
      Chef::Log.info("Skipping package - empty string")
      next
    end
    
    case node[:platform]
    when "centos","redhat","fedora","suse"
      pkgdata = package.split('.')
      name = pkgdata.shift
      architecture = pkgdata.shift
      yum_package "#{name}" do
        arch architecture if architecture
        action :remove
        ignore_failure true
      end
    when "debian","ubuntu"
      ruby_block 'Check for dpkg lock' do
        block do   
          sleep rand(10)
          retry_count = 0
          while system('lsof /var/lib/dpkg/lock') && retry_count < 20
            Chef::Log.warn("Found lock. Will retry package #{name} in #{node.workorder.rfcCi.ciName}")
            sleep rand(5)+10
            retry_count += 1
          end
        end
      end
    
      package "#{name}" do
        action :remove
        ignore_failure true
      end
    end
  end
end

