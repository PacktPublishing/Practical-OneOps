#
# Cookbook Name:: apache
# Recipe:: restart
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

apache_service = "apache2"
case node.platform
when "redhat","centos","fedora"
  apache_service = "httpd"
end

service apache_service do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end
