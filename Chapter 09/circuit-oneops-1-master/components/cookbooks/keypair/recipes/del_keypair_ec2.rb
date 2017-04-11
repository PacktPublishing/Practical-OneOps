require 'fog'

#
# supports aws ec2 keypair::delete
#

cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'AWS',
  :region => token[:region],
  :aws_access_key_id => token[:key],
  :aws_secret_access_key => token[:secret]
})

# delete if exists  
if !conn.key_pairs.get(node.kp_name).nil?

  conn.delete_key_pair(node.kp_name)
  Chef::Log.info("deleted keypair: #{node.kp_name}")

else
  Chef::Log.info("already deleted keypair: #{node.kp_name}")  
end

