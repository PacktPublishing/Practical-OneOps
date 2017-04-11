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
# rackspace::get_lb_service
#

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

cloud = cloud_service[:ciAttributes]

conn = Fog::Rackspace::LoadBalancers.new({
  :rackspace_api_key => cloud[:password],
  :rackspace_username => cloud[:username],
  :rackspace_region => cloud[:region].downcase
})

node.set[:rackspace_lb_service] = conn
