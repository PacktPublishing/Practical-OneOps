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
# Recipe:: get_infoblox_connection
#

require 'excon'

cloud_name = node[:workorder][:cloud][:ciName]
service = node[:workorder][:services][:dns][cloud_name][:ciAttributes]

host = service[:host]
username = service[:username]
password = service[:password]
domain_name = service[:zone]

# Fail fast if it can't connect to infoblox. This is useful if
# we have supplied the wrong credentials in cloud.
def checkCxn(conn)
  res =  conn.request(:method=>:get,:path=>"/wapi/v1.0/network")
  if(res.status != 200)
    raise res.body
  end
end

encoded = Base64.encode64("#{username}:#{password}").gsub("\n","")
conn = Excon.new('https://'+host,
  :headers => {'Authorization' => "Basic #{encoded}"}, :ssl_verify_peer => false)

# Validate the connection.
checkCxn(conn)

# Set the connection object
node.set["infoblox_conn"] = conn
