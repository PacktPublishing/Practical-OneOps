# netscaler::delete_lb_group

lbgroup_name = node.workorder.rfcCi.ciName+'-'+node.workorder.rfcCi.ciId.to_s

# unbind each loadbalancer
lbs = node.dcloadbalancers + node.loadbalancers
lbs.each do |lb|
  binding = {
    :name => lbgroup_name,
    :vservername => lb[:name]
  }
  Chef::Log.info("unbind lbgroup: #{binding}")  
  
  req = 'object={"params":{"action": "unbind"}, "lbgroup_lbvserver_binding" : ' + JSON.dump(binding) + '}'    
  resp_obj = JSON.parse(node.ns_conn.request(:method=>:post,
    :path=>"/nitro/v1/config/",
    :body => req ).body)
  
  if resp_obj["errorcode"] != 0 && 
     resp_obj["errorcode"] != 461 && # binding already removed
     resp_obj["errorcode"] != 2370 && # lbgroup already removed  
     resp_obj["errorcode"] != 2641 # lbgroup already removed
               
    Chef::Log.error("lbgroup unbind fail: "+resp_obj.inspect)       
      exit 1
  end
end
