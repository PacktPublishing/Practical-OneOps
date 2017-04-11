#
# Cookbook Name:: fqdn
# Recipe:: get_fog_connection
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

require 'fog'

cloud_name = node[:workorder][:cloud][:ciName]
service_class = node[:workorder][:services][:dns][cloud_name][:ciClassName].split(".").last.downcase
dns_attrs = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
  
dns = nil
domain_name = dns_attrs[:zone] 
case service_class
when /rackspace/
  dns = Fog::DNS.new(
    :provider => 'rackspace',
    :rackspace_username => dns_attrs[:username],
    :rackspace_api_key => dns_attrs[:api_key]
  )
when /route53/
  dns = Fog::DNS.new(
    :provider => 'AWS',
    :aws_access_key_id => dns_attrs[:key],
    :aws_secret_access_key => dns_attrs[:secret]
  ) 
  domain_name += "."
end

node.set["dns_service_class"] = service_class

if dns.nil?
  Chef::Log.error("unsupported service_class: #{service_class}")
  exit 1
end


zone = dns.zones.find { |z| z.domain == domain_name }
if zone.nil?
  zone = dns.zones.create(
    :domain => domain_name,
    :email => node.workorder.payLoad[:Assembly].first[:ciAttributes][:owner] )
end

if zone.nil?
  Chef::Log.error("could not get or create zone: #{domain_name}")
  exit 1
end
node.set["fog_zone"] = zone
