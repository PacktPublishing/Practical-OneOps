#
# construct monitor name
#

if node.workorder.has_key?("rfcCi")
  lbCi = node.workorder.rfcCi
else
  lbCi = node.workorder.ci  
end


iport_map = {}
JSON.parse(lbCi["ciAttributes"]["listeners"]).each do |lb|
  iport = lb.split(" ").last
  iport_map[iport] = lb.split(" ")[2]
end


previous_iport_map = {}
if lbCi.has_key?("ciBaseAttributes") &&
   lbCi["ciBaseAttributes"].has_key?("listeners")  
  
  JSON.parse(lbCi["ciBaseAttributes"]["listeners"]).each do |lb|
    previous_iport = lb.split(" ").last
    previous_iport_map[previous_iport] = 1
  end  
end

ecv_map = JSON.parse(lbCi["ciAttributes"]["ecv_map"])

env_name = node.workorder.payLoad.Environment[0]["ciName"]
assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
platform_name = node.workorder.box.ciName
cloud_name = node.workorder.cloud.ciName

lb_ci_id = lbCi["ciId"].to_s

monitors = []
old_monitor_names = []
iport_map.each_pair do |iport,protocol|
  
  iport_name = iport
  if iport.downcase == 'any'
    next
  end  
  base_monitor_name =  [env_name, assembly_name, platform_name, iport, lb_ci_id].join("-") + "-monitor"
  
  sg_name = [env_name, platform_name, cloud_name, iport, lb_ci_id, "svcgrp"].join("-")
  # truncate for netscaler max monitor name length of 31 - port can be 5
  if base_monitor_name.length > 26
    base_monitor_name = lb_ci_id + "-"+ iport +"-monitor"
  end
  
  monitor_request = 'get /'
  if ecv_map.has_key?(iport)
    monitor_request = ecv_map[iport].downcase
  end

  # use generic monitors
  orig_monitor_name = ""
  if ["get /","head /"].include?(monitor_request)
    # orig monitor name to migrate in servicegroup before binding
    orig_monitor_name  = base_monitor_name    
    base_monitor_name = "generic-" + monitor_request.gsub(' ','-').gsub('/','slash')
  else
    # check for non-generic bindings and add to old monitors to unbind
    existing_bindings =    
    resp_obj = JSON.parse(node.ns_conn.request(:method=>:get,
      :path=>"/nitro/v1/config/servicegroup_lbmonitor_binding/#{sg_name}").body)
    
    if resp_obj.has_key? "servicegroup_lbmonitor_binding"
      resp_obj['servicegroup_lbmonitor_binding'].each do |binding|
        
        if binding['monitor_name'] != base_monitor_name
          old_monitor_names.push binding['monitor_name']
          Chef::Log.info("adding to old monitors: #{binding['monitor_name']}")
        end
        
      end
    end
  
  end
    
  monitor = {
    :monitor_name => base_monitor_name, 
    :iport => iport, 
    :protocol => protocol,
    :sg_name => sg_name 
  }
  if !orig_monitor_name.empty?
    monitor[:orig_monitor_name] = orig_monitor_name
  end
  monitors.push monitor
  
  # setup old name to unbind and delete
  if previous_iport_map.has_key? iport
    previous_iport_map.delete iport
  end
end

node.set["monitors"] = monitors

# cleanup monitors
previous_iport_map.keys.each do |iport|
  base_monitor_name =  [env_name, assembly_name, platform_name, iport, lb_ci_id].join("-") + "-monitor"
  
  # truncate for netscaler max monitor name length of 31 - port can be 5
  if base_monitor_name.length > 26
    base_monitor_name = lb_ci_id + "-"+ iport +"-monitor"
  end
  
  monitor_name = base_monitor_name
  old_monitor_names.push monitor_name
end
node.set["old_monitor_names"] = old_monitor_names
