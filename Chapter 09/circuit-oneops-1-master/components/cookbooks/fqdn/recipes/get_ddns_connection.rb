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
# Cookbook Name:: fqdn
# Recipe:: get_ddns_connection
#

cloud_name = node[:workorder][:cloud][:ciName]
service = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
  
auth_content = "key #{service[:keyname]} {\n"
auth_content += "  secret \"#{service[:secret]}\";\n"
auth_content += "  algorithm #{service[:algorithm]};\n"
auth_content += "};\n"  

filename = '/tmp/ddns' + (0..16).to_a.map{|a| rand(16).to_s(16)}.join
File.open(filename, 'w') { |file| file.write(auth_content) }  
node.set["ddns_key_file"] = filename
node.set["ddns_header"] = "server #{node.ns}\nzone #{service[:zone]}\n"
