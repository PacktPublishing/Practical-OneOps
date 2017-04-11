#
# Cookbook Name:: haproxy
# Recipe:: delete_lb
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

require 'excon'

#extend Haproxy::Base
#Chef::Resource::RubyBlock.send(:include, Haproxy::Base)

# delete_lb not factored out to util/base class due to chef errors with:
# NameError - uninitialized constant Chef::Recipe::Haproxy when either of 
# the lines above are uncommented ; still checking on non-code dup solution

def delete_lb(conn,lb_name)
  Chef::Log.info("delete lb name: "+lb_name)
  
  # frontend
  response = conn.request(:method => :get, :path => "/frontend/#{lb_name}")      
  puts "response: #{response.inspect}"
  if response.status == 200 
    delete_response = conn.request(:method => :delete, :path => "/frontend/#{lb_name}")
    if response.status == 200
      Chef::Log.info("delete from frontend #{lb_name} done.")
    else
      Chef::Log.error("delete from frontend #{lb_name} failed:")
      puts delete_response.inspect
      exit 1
    end
  else
    Chef::Log.info("already deleted frontend: #{lb_name}")
  end
        
  # backend
  lb_name += "-backend"  
  response = conn.request(:method => :get, :path => "/backend/#{lb_name}")      
  puts "response: #{response.inspect}"
  if response.status == 200 
    delete_response = conn.request(:method => :delete, :path => "/backend/#{lb_name}")
    if response.status == 200
      Chef::Log.info("delete from backend #{lb_name} done.")
    else
      Chef::Log.error("delete from backend #{lb_name} failed:")
      puts delete_response.inspect
      exit 1
    end
  else
    Chef::Log.info("already deleted backend: #{lb_name}")
  end
        
end



cloud_name = node.workorder.cloud.ciName
service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
Chef::Log.info("endpoint: #{service[:endpoint]}")

conn = Excon.new(service[:endpoint], 
#  :user => service[:username], 
#  :password => service[:password], 
  :ssl_verify_peer => false)
  
node.loadbalancers.each do |lb_def|
  delete_lb(conn,lb_def[:name])
end
