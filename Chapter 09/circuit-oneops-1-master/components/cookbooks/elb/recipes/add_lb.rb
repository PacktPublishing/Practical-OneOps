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
instances = Array.new
computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
computes.each do |compute|
  instance_id = compute["ciAttributes"]["instance_id"]
  instances.push(instance_id)
end


node.loadbalancers.each do |lb_def|
    
  # elb cannot handle dots
  lb_name = lb_def[:name].gsub(".","-")
  Chef::Log.info("lb name: "+lb_name)

  Chef::Log.info("creating elb lb_name: #{lb_name}")
  elb_conn = Fog::AWS::ELB.new(
    :aws_access_key_id => cloud_service[:ciAttributes][:key],
    :aws_secret_access_key => cloud_service[:ciAttributes][:secret],
    :region => cloud_service[:ciAttributes][:region]
  )
  
  availability_zones = {}
  node.workorder.payLoad[:DependsOn].each do |c|
    if c[:ciAttributes].has_key?("availability_zone")
      az = c[:ciAttributes][:availability_zone]
      availability_zones[az] = 1
    end
  end
  listeners = []
  JSON.parse(node.lb.listeners).each do |listener|
     l = listener.split(" ")  
     listeners.push({ 
       "Protocol" => l[0], 
       "LoadBalancerPort" => l[1], 
       "InstanceProtocol" => l[2],
       "InstancePort" => l[3]})
  end
  
  puts "listeners: #{listeners.inspect}"
  
  begin
    result = elb_conn.create_load_balancer(availability_zones.keys, lb_name, listeners)
  rescue Fog::AWS::ELB::IdentifierTaken => e
    if e.message =~ /configured with different parameters/
      result = elb_conn.delete_load_balancer(lb_name)
      if result.status != 200
        puts "ELB creation failed!"
        puts "result: #{result.inspect}"
        exit 1
      end
      retry
    end
  end
  
  result = elb_conn.register_instances(instances,lb_name)
  if result.status != 200
    puts "register instances creation failed!"
    puts "result: #{result.inspect}"
    exit 1
  end

  elb = elb_conn.load_balancers.get(lb_name)
  puts "elb: #{elb.inspect}"
  node.set["lb_dns_name"] = elb.dns_name

end
