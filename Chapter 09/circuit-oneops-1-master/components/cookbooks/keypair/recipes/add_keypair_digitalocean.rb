require 'fog/digitalocean'


cloud_name = node[:workorder][:cloud][:ciName]
attributes = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
Chef::Log.debug("Public key: " + node.keypair.public)
conn = Fog::Compute.new({
  :provider => 'DigitalOcean',
  :digitalocean_token => attributes[:key]
})
key = conn.ssh_keys.get(node.kp_name)
if key == nil
  key = conn.ssh_keys.create(
      :name => node.kp_name, 
      :ssh_pub_key => node.keypair.public,
      :public_key => node.keypair.public
  )
  Chef::Log.info("import keypair: " + key.inspect)
else
  Chef::Log.info("existing keypair: #{key.inspect}")  
end

