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

cloud_name = node.workorder.cloud.ciName
cloud_service = nil
dns_service = nil
if !node.workorder.services["lb"].nil? &&
  !node.workorder.services["lb"][cloud_name].nil?
  
  cloud_service = node.workorder.services["lb"][cloud_name]
  dns_service = node.workorder.services["dns"][cloud_name]
end

if cloud_service.nil? || dns_service.nil?
  Chef::Log.error("missing cloud service. services: "+node.workorder.services.inspect)
  exit 1
end

cloud_dns_id = cloud_service[:ciAttributes][:cloud_dns_id] || 'glb'
env_name = node.workorder.payLoad.Environment[0]["ciName"]
asmb_name = node.workorder.payLoad.Assembly[0]["ciName"]
org_name = node.workorder.payLoad.Organization[0]["ciName"]
dns_zone = dns_service[:ciAttributes][:zone]

if !cloud_service[:ciAttributes].has_key?("gslb_site_dns_id")
  msg = "gdns service for #{cloud_name} needs gslb_site_dns_id attr populated"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end    
    
dc_dns_zone = cloud_service[:ciAttributes][:gslb_site_dns_id]+"."+dns_service[:ciAttributes][:zone]
# remote_dc_dns_zone = cloud_service[:ciAttributes][:gslb_site_dns_id]+"-remote."+dns_service[:ciAttributes][:zone]

ci = {}
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci  
end  


def get_ns_service_type(cloud_service_type, service_type)
  case cloud_service_type
  when "cloud.service.Netscaler"
    
    case service_type.upcase
    when "HTTPS"
      service_type = "SSL"
    end
    
  end
  return service_type.upcase
end

service_type = get_ns_service_type(cloud_service[:ciClassName],ci[:ciAttributes][:protocol])
vport = ci[:ciAttributes][:vport]
iport = ci[:ciAttributes][:iport]


vport_old = vport
if ci.has_key?("ciBaseAttributes") &&
   ci[:ciBaseAttributes].has_key?("vport")
  
  vport_old = ci[:ciBaseAttributes][:vport]
end

service_type_old = service_type
if ci.has_key?("ciBaseAttributes") &&
   ci[:ciBaseAttributes].has_key?("protocol")
  
  service_type_old = get_ns_service_type(cloud_service[:ciClassName],ci[:ciBaseAttributes][:protocol])
end


node.set["ns_lb_iport"] = iport
node.set["ns_lb_vport"] = vport 
node.set["ns_service_type"] = service_type 
node.set["ns_iport_service_type"] = get_ns_service_type(cloud_service[:ciClassName],ci[:ciAttributes][:iprotocol])


platform = node.workorder.box
platform_name = node.workorder.box.ciName

# env-platform.glb.domain.domain.domain-servicetype_tcp[port]-lb
# d1-pricing.glb.dev.x.com-HTTP_tcp80-lb

loadbalancers = Array.new
cleanup_loadbalancers = Array.new

# primary lb - neteng convention
lb_name = [env_name, platform_name, 'glb', dns_zone].join(".") + '-'+service_type+"_"+vport+"tcp" +'-' + ci[:ciId].to_s + "-lb"

lb = {
  :name => lb_name,
  :iport => iport,
  :vport => vport,
  :service_type => service_type
}
loadbalancers.push(lb)


# dc lb - example: web.prod-1312.core.oneops.dfw.prod.walmart.com-SSL_BRIDGE_443tcp-lb
dc_lb_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".") + 
             '-'+service_type+"_"+vport+"tcp-" + platform[:ciId].to_s + "-lb"
             
# remote_dc_lb_name = [platform_name, env_name, asmb_name, org_name, remote_dc_dns_zone].join(".") + 
#                     '-'+service_type+"_"+vport+"tcp-" + platform[:ciId].to_s + "-lb"


dc_lb = {
  :name => dc_lb_name,
  :iport => iport,
  :vport => vport,
  :service_type => service_type
}

if node.workorder.cloud.ciAttributes.has_key?("priority") &&
  node.workorder.cloud.ciAttributes.priority.to_i != 1
  
  dc_lb[:is_secondary] = true
  
end


# skip deletes if other active clouds for same dc
has_other_cloud_in_dc_active = false
if node.workorder.payLoad.has_key?("primaryactiveclouds")
  node.workorder.payLoad["primaryactiveclouds"].each do |lb_service|
    if lb_service[:ciAttributes][:gslb_site_dns_id] == cloud_service[:ciAttributes][:gslb_site_dns_id] &&
       lb_service[:nsPath] != cloud_service[:nsPath]
      has_other_cloud_in_dc_active = true
      Chef::Log.info("active cloud in same dc: "+lb_service[:nsPath].split("/").last)
    end
  end
end


if node.workorder.rfcCi.rfcAction == "delete" && has_other_cloud_in_dc_active   
  Chef::Log.info("skipping delete of dc vip")
  dcloadbalancers = []
else
  node.set["dcloadbalancer"] = dc_lb
  dcloadbalancers = [dc_lb]
end

# additional ports/listeners
additional_ports = {}
old_ports = {}
if ci[:ciAttributes].has_key?("additional_port_map")
  additional_ports = JSON.parse(ci[:ciAttributes][:additional_port_map])
end
if ci.has_key?("ciBaseAttributes") && ci[:ciBaseAttributes].has_key?("additional_port_map")
  old_ports = JSON.parse(ci[:ciBaseAttributes][:additional_port_map])
end


additional_ports.each do |type, port|
  service_type = get_ns_service_type(cloud_service[:ciClassName],type)
  lb_name = [env_name, platform_name, 'glb', dns_zone].join(".") + '-'+service_type+"_"+port+"tcp" +'-' + ci[:ciId].to_s + "-lb"
  lb = {
    :name => lb_name,
    :iport => iport,
    :vport => port,
    :service_type => service_type
  }
  loadbalancers.push(lb)
  
  dc_lb_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".") + 
               '-'+service_type+"_"+port+"tcp-" + platform[:ciId].to_s + "-lb"  
  dc_lb = {
    :name => dc_lb_name,
    :iport => iport,
    :vport => port,
    :service_type => service_type    
  }
  if node.workorder.cloud.ciAttributes.has_key?("priority") &&
    node.workorder.cloud.ciAttributes.priority.to_i != 1
    
    dc_lb[:is_secondary] = true
    
  end
    
  if node.workorder.rfcCi.rfcAction == "delete" &&  
     has_other_cloud_in_dc_active   
    Chef::Log.info("skipping delete of dc vip")
  else
    dcloadbalancers.push(dc_lb)
  end
end


# delete old lb vserver if name (composite of port,type)
if service_type_old != service_type || vport_old != vport

  lb_name = [env_name, platform_name, 'glb', dns_zone].join(".") + '-'+service_type_old+"_"+vport_old+"tcp" +'-' + ci[:ciId].to_s + "-lb"

  lb = {
    :name => lb_name,
    :iport => iport,
    :vport => vport_old,
    :service_type => service_type_old
  }

  found = false
  
  loadbalancers.each do |l|
    if l[:name] == lb_name
      found = true
      break
    end
  end
  
  if !found   
    cleanup_loadbalancers.push(lb) 
  end

  dc_lb_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".") + 
             '-'+service_type_old+"_"+vport_old+"tcp-" + platform[:ciId].to_s + "-lb"

  dcloadbalancers.each do |l|
    if l[:name] == dc_lb_name
      found = true
      break
    end
  end
  
  if !found   
    lb = {
      :name => dc_lb_name,
      :iport => iport,
      :vport => vport_old,
      :service_type => service_type_old
    }  
    cleanup_loadbalancers.push(lb) 
  end            
  
end


old_ports.each do |type,port|
  service_type = get_ns_service_type(cloud_service[:ciClassName],type)
  lb_name = [env_name, platform_name, 'glb', dns_zone].join(".") + '-'+service_type+"_"+port+"tcp" +'-' + ci[:ciId].to_s + "-lb"
  dc_lb_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".") + 
             '-'+service_type_old+"_"+port+"tcp-" + platform[:ciId].to_s + "-lb"
             
  found = false
  
  loadbalancers.each do |l|
    if l[:name] == lb_name
      found = true
      break
    end
  end
  
  if !found
    lb = {
      :name => lb_name,
      :iport => iport,
      :vport => port,
      :service_type => service_type
    }
    cleanup_loadbalancers.push(lb)    
  end

  found = false
  
  dcloadbalancers.each do |l|
    if l[:name] == dc_lb_name
      found = true
      break
    end
  end
  
  if !found
    lb = {
      :name => dc_lb_name,
      :iport => iport,
      :vport => port,
      :service_type => service_type
    }
    cleanup_loadbalancers.push(lb)    
  end

  
end



node.set["loadbalancers"] = loadbalancers
node.set["dcloadbalancers"] = dcloadbalancers
node.set["cleanup_loadbalancers"] = cleanup_loadbalancers

if cloud_service[:ciClassName] != "cloud.service.Netscaler"
  node.set["lb_name"] = [env_name, platform_name, ci[:ciId].to_s].join(".")  
end
