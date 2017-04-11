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

#
# Cookbook Name:: java
# Recipe:: openjdk
#
# Installation guide - http://openjdk.java.net/install/
#

extend Java::Util

version = node[:java][:version]
pkg = node[:java][:jrejdk]

case node['platform_family']
  when 'rhel'
    # As of now, OpenJDK Server JRE is not supported in RHEL.
    if pkg == 'server-jre'
      exit_with_err "OpenJDK #{pkg} package is not available on #{node[:platform]}. Use Oracle flavor."
    end
  when 'debian'
end

pkg_name = get_java_ospkg_name(node['platform_family'], version, pkg)
Chef::Log.info "Java package name to be installed: #{pkg_name}"

package "#{pkg_name}"
log "OpenJDK-#{version} #{pkg} package installation is done!"


