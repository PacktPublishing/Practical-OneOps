#
# Cookbook Name:: netscaler
# Recipe:: del_servicegroup
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

n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)

lbs = node.loadbalancers + node.dcloadbalancers

deleted_list = []

lbs.each do |lb|      
  next if deleted_list.include?(lb[:sg_name])
    
  n = netscaler_servicegroup lb[:sg_name] do
    connection node.ns_conn
    action :nothing
  end
  n.run_action(:delete)
  deleted_list.push(lb[:sg_name])
end
  

include_recipe "netscaler::delete_monitor"
