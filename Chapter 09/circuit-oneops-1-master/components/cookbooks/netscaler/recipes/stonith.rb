#
# Cookbook Name:: netscaler
# Recipe:: stonith
#
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


# this is used to unbind secondary clouds from dc level vips first - before promoting
cloud_name = node.workorder.cloud.ciName
cloud_services = []
if node.workorder.payLoad["stonithlbservice"].nil? ||
   node.workorder.payLoad["stonithlb"].nil?  
  return  
end
  
cloud_services = node.workorder.payLoad["stonithlbservice"]
lbs = node.workorder.payLoad["stonithlb"]

cloud_services.each do |lb_service|
      
  lbs.each do |lb|

    dc_name = lb_service[:ciAttributes][:gslb_site_dns_id]  
    
    if lb['ciAttributes'].has_key?('availability_zone') &&
       !lb['ciAttributes']['availability_zone'].empty?
     
      availability_zones = JSON.parse(lb_service[:ciAttributes][:availability_zones])
      az = lb['ciAttributes']['availability_zone']      
      host = availability_zones[az]
    else
      Chef::Log.info("no lb az - skipping stonith for #{dc_name}")
      next
    end
    Chef::Log.info("stonith: #{dc_name} via host: #{host}")

    username = lb_service[:ciAttributes][:username]
    password = lb_service[:ciAttributes][:password]
  
    Chef::Log.info("connecting to netscaler: #{host}")
    encoded = Base64.encode64("#{username}:#{password}").gsub("\n","")
    conn = Excon.new('https://'+host, 
      :headers => {'Authorization' => "Basic #{encoded}", 'Content-Type' => 'application/x-www-form-urlencoded'},
      :ssl_verify_peer => false)
    
    lb_name = ""
    vnames_map = {}
    if lb[:ciAttributes].has_key?("vnames")
      vnames_map = JSON.parse(lb[:ciAttributes][:vnames])
    end
    vnames_map.keys.each do |key|
      if key =~ /#{dc_name}/
        lb_name = key
        break
      end
    end
    if lb_name.empty?
      Chef::Log.info("missing dc_name: #{dc_name} in #{vnames_map.inspect}")
      next
    end
    
    sg_name = JSON.parse(lb[:ciAttributes][:inames]).first

    binding = { :name => lb_name, :servicegroupname => sg_name }  
    req = 'object={"params":{"action": "unbind"}, "lbvserver_servicegroup_binding" : ' + JSON.dump(binding) + '}'      
    resp_obj = JSON.parse(conn.request(
      :method=> :post, 
      :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lb_name}", 
      :body => req).body)      

    if resp_obj["errorcode"] != 0 && 
       (resp_obj["message"] !~ /Entity not bound/ && 
       resp_obj["message"] !~ /No such resource/)
      
      Chef::Log.error( "delete bind #{sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
      exit 1
    else
      Chef::Log.info( "delete bind #{sg_name} to #{lb_name} resp: #{resp_obj.inspect}")
    end

    
  end
  
end

