#
# supports aws ec2 secgroup::delete
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

# create if doesn't exist 
sglookup = conn.describe_security_groups('group-name' => node.secgroup_name).body['securityGroupInfo']

if sglookup.empty?
  Chef::Log.info("already deleted secgroup: #{node.secgroup_name}")
else
  sglookup.each do |g|
    conn.delete_security_group(g['groupName'])
    Chef::Log.info("deleted secgroup: #{g['groupName']} #{g['groupId']}") 
  end
end



