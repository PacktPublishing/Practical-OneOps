#
# supports aws ec2 secgroup::add
#

require 'fog'

cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'AWS',
  :region => token[:region],
  :aws_access_key_id => token[:key],
  :aws_secret_access_key => token[:secret]
})

description = node.workorder.rfcCi.ciAttributes[:description]
# aws requires populated description
if description.nil? || description.empty?
  description = node.secgroup_name
end

# create if doesn't exist 
sglookup = conn.describe_security_groups('group-name' => node.secgroup_name).body['securityGroupInfo']

if sglookup.empty?
  sg = conn.create_security_group(node.secgroup_name, description).body
  Chef::Log.info("create secgroup: #{node.secgroup_name} #{sg.inspect}")

else
  sg = sglookup.first
  Chef::Log.info("existing secgroup: #{node.secgroup_name} #{sg.inspect}")  
end

node.set[:secgroup][:group_id] = sg['groupId']
node.set[:secgroup][:group_name] = node.secgroup_name

rules = JSON.parse(node.workorder.rfcCi.ciAttributes[:inbound])
rules.each do |rule|
  (min,max,protocol,cidr) = rule.split(" ")
  begin
    r = conn.authorize_security_group_ingress(node.secgroup_name, 'FromPort' => min, 'ToPort' => max, 'IpProtocol' => protocol, 'CidrIp' => cidr)
    Chef::Log.info("rule added: #{rule}")
  rescue Exception => e  
    if e.message =~ /has already been authorized/
      Chef::Log.info("rule exists: #{rule}")
    else
      Chef::Log.fatal(e.inspect)      
    end
  end
end


