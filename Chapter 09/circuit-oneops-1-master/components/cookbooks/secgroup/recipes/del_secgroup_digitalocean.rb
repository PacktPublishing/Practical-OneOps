#
# supports aliyun ecs secgroup::delete
#

require 'fog/digitalocean'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'DigitalOcean',
  :digitalocean_url => 'https://ecs.aliyuncs.com',
  :digitalocean_token => token[:key]
})

body = JSON.parse(conn.list_security_groups.body)
Chef::Log.info("sgcontent: #{body}")
sg_exist = false

body['SecurityGroups']['SecurityGroup'].each do |sec_group|
  if sec_group['SecurityGroupName'].eql? node.secgroup_name
    conn.delete_security_group(sec_group['SecurityGroupId'])
    sg_exist = true
    Chef::Log.info("deleted secgroup: #{sec_group['SecurityGroupName']} #{sec_group['SecurityGroupId']}")
  end
end

if sg_exist == false
    Chef::Log.info("already deleted secgroup: #{node.secgroup_name}")
end
