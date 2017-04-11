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
# Cookbook Name:: secgroup
# Recipe:: delete
#

include_recipe "secgroup::setup"

if node[:provider_class] =~ /ec2|openstack|aliyun/
  include_recipe "secgroup::del_secgroup_"+node[:provider_class]
elsif node[:provider_class] =~ /azure/
  include_recipe "azuresecgroup::del_net_sec_group"
else
  Chef::Log.info("secgroup delete not implemented for provider")
end
