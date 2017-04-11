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
# Cookbook Name:: lb
# Recipe:: status
#

require 'fog'

cloud_name = node.workorder.cloud.ciName
cloud_service = nil
if !node.workorder.services["lb"].nil? &&
  !node.workorder.services["lb"][cloud_name].nil?
  
  cloud_service = node.workorder.services["lb"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.error("no cloud service defined. services: "+node.workorder.services.inspect)
  exit 1
end

if cloud_service[:ciClassName] !~ /netscaler/i
  Chef::Log.info("lb cloud service is #{cloud_service} but this action is only supported for netscaler cloud service hence exiting...")
  exit 0
end

#include_recipe "lb::get_lb_name"

lbs = []
JSON.parse(node.workorder.ci.ciAttributes.vnames).keys.each do |lb_name|
  lbs.push({:name => lb_name})
end
node.set["loadbalancers"] = lbs

# if ServiceBy exists then run the remote lb::add recipe
case cloud_service[:ciClassName]
when /netscaler/i
  include_recipe "netscaler::get_lb_status"
when /rackspace/i

when /haproxy/i

when /aws/i

end
