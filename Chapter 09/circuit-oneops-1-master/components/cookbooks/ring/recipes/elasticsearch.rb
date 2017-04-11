nodes = node.workorder.payLoad.ManagedVia

node.normal.run_list = node.run_list.dup
node.normal.run_list[1] = "recipe[ring::elasticsearch_join_cluster]"

# grab a secure key for ssh
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
ssh_key_file = "/tmp/"+puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
end

# update our local cluster
include_recipe "ring::elasticsearch_join_cluster"

chefImpl = node.workorder.rfcCi.impl
workOrderPath = "/tmp"
workOrderFile = "#{workOrderPath}/es-ring.#{node.workorder.rfcCi.ciName}.json"
file workOrderFile do
  content JSON.pretty_generate(node.normal)
  action :create
end

# now update and restart each of the other nodes so they'll join the cluster
localIp = node[:ipaddress]
nodes.each do |n|
  if (localIp != n[:ciAttributes][:private_ip])
    sendWorkOrder = "sudo scp -i #{ssh_key_file}  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null #{workOrderFile} oneops@#{n[:ciAttributes][:private_ip]}:/#{workOrderPath}/."
    execWorkOrder = "sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{n[:ciAttributes][:private_ip]} sudo components/exec-order.rb #{chefImpl} #{workOrderFile}"
    removeWorkOrder = "sudo ssh -i #{ssh_key_file}  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{n[:ciAttributes][:private_ip]} rm #{workOrderFile}"
    puts "ElasticSearch:sendWorkOrder:#{sendWorkOrder}"
    execute sendWorkOrder
    puts "ElasticSearch:execWorkOrder:#{execWorkOrder}"
    execute execWorkOrder
    puts "ElasticSearch:removeWorkOrder:#{removeWorkOrder}"
    execute removeWorkOrder
  end
end

# clean up our ssh key
file ssh_key_file do
  action :delete
end
file workOrderFile do
  action :delete
end

###DNS RECORD required for fqdn
nodes = node.workorder.payLoad.ManagedVia
dns_record = ""
nodes.each do |n|
  if dns_record == ''
    dns_record = n[:ciAttributes][:dns_record]
  else
    dns_record += ',' + n[:ciAttributes][:dns_record]
  end
end
puts "***RESULT:dns_record=#{dns_record}"
