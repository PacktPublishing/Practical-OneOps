
require 'fog/aliyun'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'aliyun',
  :aliyun_region_id => token[:region],
  :aliyun_zone_id => '', # "aliyun_zone_id" is not a required parameter
  :aliyun_url => token[:url],
  :aliyun_accesskey_id => token[:key],
  :aliyun_accesskey_secret => token[:secret]
})

#conn.images.all.each do |img|
# Chef::Log.info("img info: #{img.inspect}")
#end

description = node.workorder.rfcCi.ciAttributes[:description]
# aws requires populated description
if description.nil? || description.empty?
    description = node.secgroup_name
end

# create if doesn't exist 
body = JSON.parse(conn.list_security_groups.body)
Chef::Log.info("sgcontent: #{body}")
sg_exist = false
sec_group_id = nil

body['SecurityGroups']['SecurityGroup'].each do |sec_group|
  if sec_group['SecurityGroupName'].eql? node.secgroup_name
    sg_exist = true
    sg = sec_group
    Chef::Log.info("existing secgroup: #{node.secgroup_name} #{sg.inspect}")
    sec_group_id = sec_group['SecurityGroupId']
    break
  end
end

if sg_exist == false
    sg = conn.create_security_group(:name => node.secgroup_name, :description => description).body
    Chef::Log.info("create secgroup: #{node.secgroup_name} #{sg.inspect}")
    sec_group_id = JSON.parse(sg)['SecurityGroupId']
end

Chef::Log.info("security group ID: #{sec_group_id}")

node.set[:secgroup][:group_id] = sec_group_id
node.set[:secgroup][:group_name] = node.secgroup_name

rules = JSON.parse(node.workorder.rfcCi.ciAttributes[:inbound])
rules.each do |rule|
  (min,max,protocol,cidr) = rule.split(" ")
  port_range = min + "/" + max
  Chef::Log.info("port_range: #{port_range}")
  Chef::Log.info("cidr: #{cidr}")
  begin
    r = conn.create_security_group_ip_rule(sec_group_id, cidr, "internet", :portRange => port_range, :protocol => protocol)
    Chef::Log.info("rule added: #{rule}")
  rescue Exception => e  
    if e.message =~ /has already been authorized/
      Chef::Log.info("rule exists: #{rule}")
    else
      Chef::Log.fatal(e.inspect)      
    end
  end
end
