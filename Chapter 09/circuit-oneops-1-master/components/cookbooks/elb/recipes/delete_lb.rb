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

cloud_name = node.workorder.cloud.ciName
cloud_service = node[:workorder][:services][:lb][cloud_name]

  
conn = Fog::AWS::ELB.new(
  :aws_access_key_id => cloud_service[:ciAttributes][:key],
  :aws_secret_access_key => cloud_service[:ciAttributes][:secret],
  :region => cloud_service[:ciAttributes][:region]
)


node.loadbalancers.each do |lb_def|
  
  Chef::Log.info("lb name: "+lb_def[:name])
  lb_name = lb_def[:name].gsub(".","-")

  conn.load_balancers.all.each do |lb|
    puts "lb: #{lb.inspect}"
  end
            
  lbs = conn.load_balancers.all.select{| clb| clb.id == lb_name }
  
  lbs.each do |lb|
   lb.destroy
  end
    
end