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

require 'fog'

env_name = node.workorder.payLoad["Environment"][0]["ciName"]
cloud_name = node.workorder.cloud.ciName
platform_name = node.workorder.box.ciName
rfcCi = node.workorder.rfcCi

include_recipe "lb::build_load_balancers"
lb_name = node[:lb_name]


cloud_service = nil
if !node.workorder.services["lb"].nil? &&
  !node.workorder.services["lb"][cloud_name].nil?

  cloud_service = node.workorder.services["lb"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.error("no cloud service defined. services: "+node.workorder.services.inspect)
  exit 1
end


# nsPath":"/xcom/demo/r-aws-1/bom"
security_group_parts = node.workorder.rfcCi.nsPath.split("/")
security_group = security_group_parts[3]+'.'+security_group_parts[2]+'.'+security_group_parts[1]
Chef::Log.info("using security_group:"+security_group)


case cloud_service[:ciClassName].split(".").last.downcase
when /azure_lb/

    include_recipe "azure_lb::delete"

when /f5-bigip/

   include_recipe "f5-bigip::f5_delete_lbvserver"
   include_recipe "f5-bigip::f5_delete_pool"
   include_recipe "f5-bigip::f5_delete_monitor"
   include_recipe "f5-bigip::f5_delete_node"

when /netscaler/

  n = netscaler_connection "conn" do
    action :nothing
  end
  n.run_action(:create)

  include_recipe "netscaler::delete_lbvserver"
  include_recipe "netscaler::delete_servicegroup"
  include_recipe "netscaler::delete_server"
  include_recipe "netscaler::logout"

when /rackspace/

  include_recipe "rackspace::delete_lb"

when /elb/

  include_recipe "elb::delete_lb"

when /haproxy/

  include_recipe "haproxy::delete_lb"

when /neutron/

  include_recipe "neutron::delete_lb"
end
