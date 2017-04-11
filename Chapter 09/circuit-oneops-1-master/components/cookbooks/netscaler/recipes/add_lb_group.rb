#
# netscaler::add_lb_group - adds a lb group ns object and puts all the lbvserver in it (for session persistence)
#


# delete lb_group if disabled  
if !node.workorder.rfcCi.ciAttributes.has_key?("enable_lb_group") || 
   node.workorder.rfcCi.ciAttributes.enable_lb_group == "false" ||
  node.workorder.rfcCi.ciAttributes.stickiness == "false"
   
   Chef::Log.info("no lbgroup")
   include_recipe "netscaler::delete_lb_group"
   return
end

# to unset cookiedomain have to recreate
if node.workorder.rfcCi.ciBaseAttributes.has_key?("cookie_domain") &&
  (node.workorder.rfcCi.ciBaseAttributes.cookie_domain != "default" &&
   node.workorder.rfcCi.ciAttributes.cookie_domain == "default")
   
  include_recipe "netscaler::delete_lb_group"
end


lbgroup_name = node.workorder.rfcCi.ciName+'-'+node.workorder.rfcCi.ciId.to_s

# bind each loadbalancer
node.loadbalancers.each do |lb|
  binding = {
    :name => lbgroup_name,
    :vservername => lb[:name]
  }
  Chef::Log.info("bind lbgroup: #{binding}")  
  
  req = '{"params":{"action": "bind"}, "lbgroup_lbvserver_binding" : ' + JSON.dump(binding) + '}'    
  resp_obj = JSON.parse(node.ns_conn.request(:method=>:put,
    :path=>"/nitro/v1/config/",
    :body => req ).body)
  
  if resp_obj["errorcode"] != 0 && 
     resp_obj["errorcode"] != 2371  #already bound
    
    Chef::Log.error("lbgroup bind fail: "+resp_obj.inspect)       
    exit 1
  end
end

# set persistence type, 1440min timeout
lbgroup = { 
  :name => lbgroup_name, 
  :persistencetype => node.workorder.rfcCi.ciAttributes.persistence_type.upcase,  
  :timeout => 1440
}

if node.workorder.rfcCi.ciAttributes.cookie_domain.delete(' ') != "default"
  lbgroup[:cookiedomain] = node.workorder.rfcCi.ciAttributes.cookie_domain.delete(' ')
end

req = '{"lbgroup" : ' + JSON.dump(lbgroup) + '}'
resp_obj = JSON.parse(node.ns_conn.request(:method=>:put,
  :path=>"/nitro/v1/config/lbgroup/#{lbgroup_name}",
  :body => req ).body)  

if resp_obj["errorcode"] != 0 && resp_obj["errorcode"] != 258
  Chef::Log.error("lbgroup fail: "+resp_obj.inspect)       
  exit 1
end
