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

# Cookbook Name:: fqdn
# Recipe:: remove_ptr_fog
#

extend Fqdn::Base
Chef::Resource::RubyBlock.send(:include, Fqdn::Base)
          
ip = node.workorder.rfcCi.ciAttributes.public_ip
ptr = `dig +short -x #{ip}`.split("\n")

if ptr.size > 0  
  include_recipe "fqdn::get_ddns_connection"
  ddns_execute "update delete " + ip.split('.').reverse.join('.') + ".in-addr.arpa. PTR"   
end    
