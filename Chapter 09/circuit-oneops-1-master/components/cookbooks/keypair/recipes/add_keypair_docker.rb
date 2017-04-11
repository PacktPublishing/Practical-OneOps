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
compute = node[:workorder][:payLoad]['secures'].first
nspath = rfcCi["nsPath"].split("/").delete_if {|x| x.empty? || x == "bom" }
image_org = nspath.shift
image_version = nspath.pop
image_name = nspath.join('-')
imagemap = JSON.parse( cloud[:imagemap] )
ostype = compute[:ciAttributes][:ostype]

if !compute[:ciAttributes][:image_id].nil? && !compute[:ciAttributes][:image_id].empty?
  image_id = compute[:ciAttributes][:image_id]
else
  image_id = imagemap[ostype]
end

docker_home = File.expand_path(cloud[:path])
docker_project = [ docker_home, rfcCi["nsPath"] ].join('/')

Chef::Log.info("dockerfile in #{docker_project} with image #{image_id}")

directory "#{docker_project}" do
  mode "0755"
  recursive true
  action :create
end


case ostype

when "centos-7.0", "redhat-7.0"

  template "#{docker_project}/Dockerfile" do
    source "Dockerfile_systemd.erb"
    mode 0644
    variables({ :image_id => image_id, :image_name => image_name })
  end

  cookbook_file "dbus.service" do
    path "#{docker_project}/dbus.service"
    action :create_if_missing
  end

else

  template "#{docker_project}/Dockerfile" do
    source "Dockerfile.erb"
    mode 0644
    variables({ :image_id => image_id, :image_name => image_name })
  end

  cookbook_file "init" do
    path "#{docker_project}/init"
    mode 0755
  end

end


file "authorized_keys" do
  path "#{docker_project}/authorized_keys"
  mode 0644
  content rfcCi[:ciAttributes][:public]
end

execute "build #{image_org}/#{image_name}:#{image_version}" do
  command "docker build -t=\"#{image_org}/#{image_name}:#{image_version}\" --rm ."
  cwd docker_project
end
