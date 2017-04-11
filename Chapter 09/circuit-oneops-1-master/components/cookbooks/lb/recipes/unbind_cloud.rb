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
# Recipe:: unbind_cloud
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

if cloud_service[:ciClassName] !~ /netscaler|f5/i
  Chef::Log.info("lb cloud service is #{cloud_service} but this action is only supported for netscaler Or F5-BigIP cloud service hence exiting...")
  exit 0
end

#include_recipe "lb::get_lb_name"

lbs = []
JSON.parse(node.workorder.ci.ciAttributes.vnames).keys.each do |lb_name|
  vproto = lb_name.rpartition('_')[0].rpartition('-')[2].downcase
  vport = lb_name.rpartition('_')[2].partition('tcp')[0]
  sg_name = []
  JSON.parse(node.workorder.ci.ciAttributes.listeners).each do |l|
    larr = l.split(" ")
    if larr[0] == "https"
      larr[0] = "ssl"
    end
    
    if larr[0] == vproto && larr[1] == vport
      sg_name = sg_name | JSON.parse(node.workorder.ci.ciAttributes.inames).select{|v| v.include? "-" + larr[3] + "-" }
    end 
  end
  lbs.push({:name => lb_name, :sg => sg_name})
end

node.set["loadbalancers"] = lbs

case cloud_service[:ciClassName]
when /netscaler/i
  include_recipe "netscaler::unbind_sg"
when /f5/i
  JSON.parse(node.workorder.ci.ciAttributes.vnames).keys.each do |lb_name|
    vport = lb_name.rpartition('_')[2].partition('tcp')[0]
    vproto = lb_name.rpartition('_')[0].rpartition('-')[2].downcase
    lbs.push({:name => lb_name, :vport => vport, :vprotocol => vproto})
  end
  node.set["loadbalancers"] = lbs
  node.set["lb_details"] = JSON.parse(node.workorder.ci.ciAttributes.vnames)
  include_recipe "f5-bigip::unbind_pool"
when /rackspace/i

when /haproxy/i

when /aws/i

end
