#
# supports openstack keypair::delete
#
cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'DigitalOcean',
  :digitalocean_token => token[:key]
})
node.set["kp_name"] = node.kp_name.gsub(".","-")

# delete if exists  
if !conn.ssh_keys.get(node.kp_name).nil?
  
  conn.ssh_key.destroy(node.kp_name)
  Chef::Log.info("deleted keypair: #{node.kp_name}")

else
  Chef::Log.info("already deleted keypair: #{node.kp_name}")  
end
