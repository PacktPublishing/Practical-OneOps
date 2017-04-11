# Cookbook Name:: set
# Recipe:: delete
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

container = node.workorder.payLoad.DependsOn.select { |o| o[:ciClassName].split('.').last == "Container" }.first
Chef::Log.debug("container: #{container.inspect}")
node.set[:container] = container
nsPathParts = container["nsPath"].split("/")
node.set[:container_name] = node.workorder.box.ciName
node.set[:service_name] = node[:container_name]

cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["container"].nil? &&
  !node.workorder.services["container"][cloud_name].nil?
  cloud_service = node.workorder.services["container"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.fatal!("no container cloud service defined. services: "+node.workorder.services.inspect)
end

Chef::Log.info("Container Cloud Service: #{cloud_service[:ciClassName]}")

case cloud_service[:ciClassName].split(".").last.downcase
when /kubernetes/
  include_recipe "kubernetes::delete_set"
when /swarm/
  include_recipe "swarm::delete_set"
when /ecs/
  include_recipe "ecs::delete_set"
else
  Chef::Log.fatal!("Container Cloud Service: #{cloud_service[:ciClassName]}")
end
