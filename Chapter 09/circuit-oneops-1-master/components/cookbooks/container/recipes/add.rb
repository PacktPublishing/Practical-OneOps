# Cookbook Name:: container
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

rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
# TODO if entrypoint payload use platform name, otherwise use component name
#node.set[:container_name] = node.workorder.box.ciName+'-'+rfcCi["ciId"].to_s
node.set[:container_name] = node.workorder.box.ciName
node.set[:container_labels] = {
  'organization' => nsPathParts[1],
  'assembly' => nsPathParts[2],
  'environment' => nsPathParts[3]
}

image = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Image/ }
if image.empty?
  raise "Not able to get image dependency"
else
  image_name = image.first['ciAttributes']['image_url']
  if image_name && !image_name.empty?
    Chef::Log.info("Using image name #{image_name}")
    node.set[:image_name] = image_name
  else
    raise "Empty image name attribute"
  end
end

cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["container"].nil? &&
  !node.workorder.services["container"][cloud_name].nil?
  cloud_service = node.workorder.services["container"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.fatal("no container cloud service defined. services: "+node.workorder.services.inspect)
end

Chef::Log.info("Container Cloud Service: #{cloud_service[:ciClassName]}")

case cloud_service[:ciClassName].split(".").last.downcase
when /kubernetes/
  include_recipe "kubernetes::add_container"
when /swarm/
  include_recipe "swarm::add_container"
when /ecs/
  include_recipe "ecs::add_container"
else
  Chef::Log.error("Container Cloud Service: #{cloud_service[:ciClassName]}")
  raise
end
