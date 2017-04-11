#
# supports openstack keypair::delete
#
conn = node[:iaas_provider]

node.set["kp_name"] = node.kp_name.gsub(".","-")

# delete if exists  
if !conn.key_pairs.get(node.kp_name).nil?
  
  conn.delete_keypair(node.kp_name)
  Chef::Log.info("deleted keypair: #{node.kp_name}")

else
  Chef::Log.info("already deleted keypair: #{node.kp_name}")  
end
