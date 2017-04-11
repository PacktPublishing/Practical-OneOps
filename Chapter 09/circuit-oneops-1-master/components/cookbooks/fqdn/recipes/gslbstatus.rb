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
# Cookbook Name:: gslb
# Recipe:: status
#

lbs = []
JSON.parse(node.workorder.ci.ciAttributes.gslb_vnames).keys.each do |lb_name|
  lbs.push({:name => lb_name})
end
node.set["loadbalancers"] = lbs

cloud_name = node.workorder.cloud.ciName
if !node.workorder.services["gdns"].nil? &&
   !node.workorder.services["gdns"][cloud_name].nil?
  
  cloud_service = node.workorder.services["gdns"][cloud_name]
else
  Chef::Log.info("no gdns cloud service")
  return
end

# if ServiceBy exists then run the remote lb::add recipe
case cloud_service[:ciClassName]
when "cloud.service.Netscaler"
                  
  include_recipe "netscaler::get_gslb_vserver"
  
when "cloud.service.Rackspace"

  
when "cloud.service.Haproxy"

  
when "cloud.service.AWS"
        
end