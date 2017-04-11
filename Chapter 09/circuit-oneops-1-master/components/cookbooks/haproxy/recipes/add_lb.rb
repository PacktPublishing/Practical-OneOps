#
# Cookbook Name:: haproxy
# Recipe:: add_lb
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
node.set['lb_dns_name'] = service[:endpoint].gsub('https://','').gsub(/:\d+/,'')

conn = Excon.new(service[:endpoint], 
#  :user => service[:username], 
#  :password => service[:password], 
  :ssl_verify_peer => false)
  
# cleanup old ones if they change vport or vprotocol (name changes)
node.cleanup_loadbalancers.each do |lb|
  delete_lb(conn, lb[:name])
end  

lbmethod = node.workorder.rfcCi.ciAttributes.lbmethod.upcase

# use previous dns_record attr for ip of cloud-level lb only if cloud vips were previously created
ip = nil
if node.workorder.rfcCi.ciAttributes.has_key?("dns_record") &&
   node.workorder.rfcCi.ciBaseAttributes.has_key?("create_cloud_level_vips") &&
   node.workorder.rfcCi.ciBaseAttributes.create_cloud_level_vips == "true"
  ip = node.workorder.rfcCi.ciAttributes.dns_record
end

# servers
servers = []
computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
computes.each do |c|
  servers.push c['ciAttributes']['private_ip']
end
  
node.loadbalancers.each do |lb_def|

  lb_name = lb_def[:name]
  iport = lb_def[:iport]
  backend = nil
  frontend = nil
  Chef::Log.info("lb name: "+lb_name)

  # backend
  lb_method = node.lb.lbmethod
  iprotocol = lb_def[:iprotocol].upcase

  Chef::Log.info("/backend/#{lb_name}")
  response = conn.request(:method => :get, :path => "/backend/#{lb_name}")      
  puts "response: #{response.inspect}"
  if response.status == 200 
    backend = JSON.parse(response.body)
  end 
  action = :put
  if frontend.nil?
    action = :post
  end

  backend = { 
    :lbmethod => lb_method,
    :servers => servers,
    :port => iport,
    :server_options => { "check inter" => "5s", "rise" => 3, "fall" => 2 }
  }
  if !lb_def[:acl].empty?
    backend[:acl] = lb_def[:acl]
  end  
  
  ecvs = JSON.parse(node.lb.ecv_map)
  if ecvs.has_key?(iport.to_s)
    backend[:options] = { "httpchk" => ecvs[iport] }
  end

  response = conn.request(:method => action,
    :path => "/backend/#{lb_name}", :body => JSON.dump(backend))
          
  puts "#{action} backend: #{response.inspect}"
  
  
  # frontend
  response = conn.request(:method => :get, :path => "/frontend/#{lb_name}")      
  puts "response: #{response.inspect}"
  if response.status == 200 
    frontend = JSON.parse(response.body)
  end 
  action = :put
  if frontend.nil?
    action = :post
  end
  
  frontend = { 
    :port => lb_def[:vport],      
  }
  
  if !lb_def[:acl].empty?
    frontend[:acl] = lb_def[:acl]
    frontend[:backend_port] = iport
  end  
      
  response = JSON.parse(conn.request(:method => action,
    :path => "/frontend/#{lb_name}", :body => JSON.dump(frontend)).body)
          
  puts "#{action} frontend: #{response.inspect}"
  
end
