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
# Cookbook Name:: dotnetcli
# Recipe:: add
#


Chef::Log.info("Executing Dotnet CLI add script")

#binarydistname = node[:dotnetcli][:mirror_loc].split('/').last
filePath = node.workorder.rfcCi.ciAttributes[:folderpath]
operatingsystem = node.workorder.rfcCi.ciAttributes[:ostype]
url_public = node.workorder.rfcCi.ciAttributes[:src_url]
destfile = "#{filePath}/dotnet-core-1.0-Centos.tar.gz"

Chef::Log.info("DotNet Installation directory [ #{filePath} ]")
Chef::Log.info("DotNet destination file [ #{destfile} ]")
Chef::Log.info("Operating system [ #{operatingsystem} ]")
Chef::Log.info("public URL [ #{url_public} ]")

# Getting mirror location for dotnet package
cloud = node.workorder.cloud.ciName
cookbook = node.app_name.downcase
Chef::Log.info("Getting mirror service for #{cookbook}, cloud: #{cloud}")

mirror_svc = node[:workorder][:services][:mirror]
mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) if !mirror_svc.nil?

Chef::Log.info("Printing: mirror node svc #{mirror_svc}, mirror: #{mirror}")

base_url = ''
# Search for dotnetcli mirror
base_url = mirror['dotnetcli']# if !mirror.nil? && mirror.has_key?(:dotnetcli)

Chef::Log.info("Printing: base_url #{base_url}")

base_url = url_public if base_url.nil? || base_url.empty?

Chef::Log.info("Printing: base_url #{base_url}")

#Create directory for downloading package

execute "createdirectory" do
  command "mkdir -p #{filePath}"
end

remote_file "#{destfile}" do
  source "#{base_url}"
end
Chef::Log.info("Downloaded DotNet binary file to destination")


timewait = 15
Chef::Log.info("waiting #{timewait} seconds to create vm...")
sleep timewait

Chef::Log.info("Installing..")

execute "extract_tar" do
  cwd "#{filePath}"
  command "sudo tar -zxf #{destfile}"
end

Chef::Log.info("Extracted binary file to destination")

execute "create link" do
  command "sudo ln -sf #{filePath}/dotnet /usr/local/bin"
end

Chef::Log.info("Link created")

execute "installing packages" do
  command "sudo yum install libunwind libicu -y || true"
end

Chef::Log.info("Dotnet Pack Installed and ready.")
