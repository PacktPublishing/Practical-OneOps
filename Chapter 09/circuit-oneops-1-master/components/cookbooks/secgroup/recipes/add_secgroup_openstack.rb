#
# openstack secgroup::add
#
require 'fog/openstack'
require 'resolv'

# openstack doesnt like '.'
node.set["secgroup_name"] = node.secgroup_name.gsub(".","-")
description = node.workorder.rfcCi.ciAttributes[:description] || node.secgroup_name

cloud_name = node['workorder']['cloud']['ciName']
cloud = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
      
conn = Fog::Network.new({
  :provider => 'OpenStack',
  :openstack_api_key => cloud[:password],
  :openstack_username => cloud[:username],
  :openstack_tenant => cloud[:tenant],
  :openstack_auth_url => cloud[:endpoint]
})

security_groups = conn.security_groups.all.select { |g| g.name == node.secgroup_name}

if security_groups.empty?
  
  begin
    sg = conn.security_groups.create({:name => node.secgroup_name, :description => description})
    Chef::Log.info("create secgroup: "+sg.inspect)
  rescue Excon::Errors::Error =>e
    
     puts "#{e}"
     msg=""
     case e.response[:body]
     when /\"code\": 400/
      msg = JSON.parse(e.response[:body])['badRequest']['message']
      Chef::Log.error("error response body :: #{msg}")
      puts "***FAULT:FATAL=OpenStack API error: #{msg}"
      raise Excon::Errors::BadRequest, msg
     else
      msg = e.message
      puts "***FAULT:FATAL=OpenStack API error: #{msg}"
      raise Excon::Errors::Error, msg
     end
  rescue Exception => ex
      msg = ex.message
      puts "***FAULT:FATAL= #{msg}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e  
  end  
    
else
  sg = security_groups.first
  Chef::Log.info("existing secgroup: #{sg.inspect}") 
end


node.set[:secgroup][:group_id] = sg.id
node.set[:secgroup][:group_name] = sg.name
 
rules = JSON.parse(node.workorder.rfcCi.ciAttributes[:inbound])
direction = 'ingress'

rules.each do |rule|
  (min,max,protocol,cidr) = rule.split(" ")
  
  check = sg.security_group_rules.select {
    |r| (r.port_range_min.nil? && min == 'null' || r.port_range_min.to_s == min) && 
        (r.port_range_max.nil? && max == 'null' || r.port_range_max.to_s == max) && 
        r.protocol == protocol &&
        r.remote_ip_prefix == cidr
  }
  
  if check.empty?
    begin
      ethertype = ''
      ip_addr = cidr.split("/")
      if ip_addr[0] =~ Resolv::IPv4::Regex
        ethertype = 'ipv4'
      elsif ip_addr[0] =~ Resolv::IPv6::Regex || ip_addr[0] =~ Resolv::IPv6::Regex_CompressedHex || ip_addr[0] =~ Resolv::IPv6::Regex_6Hex4Dec || ip_addr[0] =~ Resolv::IPv6::Regex_8Hex || ip_addr[0] =~ Resolv::IPv6::Regex_CompressedHex4Dec
        ethertype = 'ipv6'
      end
      sg_rule = {
        :security_group_id => sg.id,
        :direction => direction,
        :remote_ip_prefix => cidr,
        :protocol => protocol,
        :ethertype => ethertype
      }
      
      if min != 'null'
        sg_rule[:port_range_min] = min.to_i
      end
      if max != 'null'
        sg_rule[:port_range_max] = max.to_i
      end
      
      Chef::Log.info("rule create: #{sg_rule}")  
      sg.security_group_rules.create(sg_rule)
      
    rescue Exception => e
      
      puts "exception: #{e}"
      
      if e.message =~ /already exists/
        Chef::Log.info("rule exists: #{rule}")
      elsif e.response[:body]  =~ /Invalid|Not enough parameters|not a valid ip network/
        puts "***FAULT:FATAL= Invalid inbound rules specified #{rule}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      elsif e.response[:body]  =~ /Quota exceeded for resources/
        puts "***FAULT:FATAL= Security group rule quota exceeded"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      else
        msg = e.message
        Chef::Log.fatal(e.inspect)
        puts "***FAULT:FATAL= #{msg}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end
    end
  else
    Chef::Log.info("rule exists: #{rule} #{check.inspect}")
  end
end  

# rm rules not configured
del_rules = []
is_del = true
sg.security_group_rules.each do |r|
  next if r.direction == 'egress'
  rules.each do |wo_rule|
    (min,max,protocol,cidr) = wo_rule.split(" ")
    if (r.port_range_min.nil? && min == 'null' || r.port_range_min.to_s == min) && 
       (r.port_range_max.nil? && max == 'null' || r.port_range_max.to_s == max) && 
       r.protocol == protocol && 
       r.remote_ip_prefix == cidr
          
      is_del = false
      break
    end    
  end  
  is_del ? del_rules.push(r) : Chef::Log.info("rule #{r.id} exists in workorder")
  is_del = true
end

del_rules.each do |dr|
  Chef::Log.info("*****deleting rule****** #{dr.inspect}")
  dr.destroy
end
