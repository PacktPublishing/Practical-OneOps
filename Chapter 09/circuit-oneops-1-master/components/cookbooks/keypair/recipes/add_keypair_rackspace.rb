#
# supports openstack keypair::add
#
require 'fog'

# create if doesn't exist  
# openstack doesnt like '.'
node.set["kp_name"] = node.kp_name.gsub(".","-")

conn = node[:iaas_provider]

key = conn.key_pairs.get(node.kp_name)
if key == nil
  key = conn.key_pairs.create(
      :name => node.kp_name, 
      :public_key => node.keypair.public
  )
  Chef::Log.info("import keypair: "+key.inspect)
else
  Chef::Log.info("existing keypair: #{key.inspect}")  
end

