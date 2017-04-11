#
# builds ssh cmd for remote compute cmd
#

unless node.workorder.payLoad.has_key? "SecuredBy"
  Chef::Log.error("unsupported, missing SecuredBy")
  return false
end

include_recipe "compute::get_ip_from_ci"

# tmp file to store private key
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
ssh_key_file = "/tmp/"+puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
end

node.set[:ssh_key_file] = ssh_key_file
node.set[:ssh_cmd] = "ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{node.ip} "
node.set[:scp_cmd] = "scp -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null SOURCE oneops@#{node.ip}:DEST "
