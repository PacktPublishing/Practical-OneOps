#
# supports aws ec2 keypair::add
#

require 'fog'

ruby_block 'openstack keypair' do
  block do
    cloud_name = node[:workorder][:cloud][:ciName]
    token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
    
    conn = Fog::Compute.new({
      :provider => 'AWS',
      :region => token[:region],
      :aws_access_key_id => token[:key],
      :aws_secret_access_key => token[:secret]
    })
    
    # create if doesn't exist  
    if conn.key_pairs.get(node.kp_name).nil?
    
      conn.import_key_pair(node.kp_name, node.keypair.public)
      Chef::Log.info("import keypair: #{node.kp_name}")
    
    else
      Chef::Log.info("existing keypair: #{node.kp_name}")  
    end
  end
end
