include_recipe 'couchbase::base'

Couchbase::Component::RingComponent.new(node).validate

nodes = node.workorder.payLoad.ManagedVia
depends_on=node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Couchbase/ }

chosen = depends_on.first
port = chosen[:ciAttributes][:port]
user = chosen[:ciAttributes][:adminuser]
pass = chosen[:ciAttributes][:adminpassword]
rampernode = chosen[:ciAttributes][:pernoderamquotamb]
clusport = chosen[:ciAttributes][:port]
	
update_notification = chosen[:ciAttributes]['updatenotification']
autofailovertime = chosen[:ciAttributes]['autofailovertime']
autocompaction = chosen[:ciAttributes]['autocompaction']
recipents = chosen[:ciAttributes]['recipents']
sender = chosen[:ciAttributes]['sender']
host = chosen[:ciAttributes]['host']
emailport=  chosen[:ciAttributes]['emailport']	
	
cli='/opt/couchbase/bin/couchbase-cli'

Chef::Log.info("autofailovertime:#{autofailovertime}")
Chef::Log.info("autocompaction:#{autocompaction}")
Chef::Log.info("recipents:#{recipents}")
Chef::Log.info("sender:#{sender}")
Chef::Log.info("host:#{host}")

updatenotification=0
if update_notification.eql? 'true'
  updatenotification = 1
end

Chef::Log.info("update_notification:#{updatenotification}")

# dns_record used for fqdn
dns_record = ""
nodes.each do |n|
  if dns_record == ''
    dns_record = n[:ciAttributes][:private_ip]
  else
    dns_record += ',' + n[:ciAttributes][:private_ip]
  end
end
puts "***RESULT:dns_record=#{dns_record}"

# Calculate the per node ram quota allocation based on the total physical memory available
# and the percentage of RAM being allocated to Couchbase on each node. 
# @param ramquota_percentage_per_node: The ram quota percentage selected in the Couchbase component
def get_ram_size_mb(ramquota_percentage_per_node)

	Chef::Log.info("ring:get_ram_size_mb: ramquota_percentage_per_node = #{ramquota_percentage_per_node} ")
	
	total_available_physical_ram = 0
	ram_quota_factor = 0.0	

	# validate ram quota percentage parameter
	if (/[0-9][0-9]%/.match(ramquota_percentage_per_node) != nil)

		if (ramquota_percentage_per_node[0,2].to_i >= 20 && ramquota_percentage_per_node[0,2].to_i <= 80)
			
			ram_quota_factor = ramquota_percentage_per_node[0,2].to_f / 100
			Chef::Log.info("ring:get_ram_size_mb: ram_quota_factor = #{ram_quota_factor}")
			
		else
			Chef::Log.info( "ring:get_ram_size_mb: Supplied value for #{ramquota_percentage_per_node} is outside the range of 20%-80%. Default to 80%")
			ram_quota_factor = 0.8
		end

	else
		Chef::Log.info( "ring:get_ram_size_mb: Invalid value for ramquota_percentage_per_node = #{ramquota_percentage_per_node}. Default to 80%")
		ram_quota_factor = 0.8
		
	end
	
	free_raw = `free`
	# extract total memory from the string
	free_mb = free_raw.split(" ")[7]
	# convert into MB
	free_mb = (free_mb.to_f / 1024).to_int
	
	# compute 80% of the available RAM 
	per_node_mb = (free_mb * ram_quota_factor).to_int
	
	return per_node_mb

end

# Setup initial couchbase cluster node
per_node_ram_quota_mb = get_ram_size_mb(rampernode)
Chef::Log.info("ring: per_node_ram_quota_mb = #{per_node_ram_quota_mb}")

# Find cluster node with most buckets
# For new node, non of the servers will have a bucket
prev_max_bucket_count = 0
matching_index = 0
nodes.each_with_index do |cluster_node, i|
  node_ip = cluster_node[:ciAttributes][:private_ip]
  Chef::Log.info("Check buckets for node_ip=#{node_ip}")

  results = `#{cli} bucket-list --cluster=#{node_ip}:#{clusport} --user=#{user} --password=#{pass}`.split(/\n/).size / 7

  Chef::Log.info("node_ip=#{node_ip} has #{results} buckets")
  
  if (results > prev_max_bucket_count) 
    prev_max_bucket_count = results
    matching_index = i
  end
end
  
cb_ip = node.workorder.payLoad.ManagedVia[matching_index][:ciAttributes][:private_ip]
server_list = `#{cli} server-list --cluster=#{cb_ip}:#{clusport} --user=#{user} --password=#{pass} | cut -f2 -d' ' | sort -u`.split(/\n/)

execute 'initalize_cluster' do
  command "sleep 5 && #{cli} cluster-init -c #{cb_ip}:#{port} --cluster-init-username=#{user} --cluster-init-password=#{pass} --cluster-init-port=#{clusport} -u #{user} -p #{pass} --cluster-ramsize=#{per_node_ram_quota_mb}"
  returns [0,1]
  action :run
end

#CB Settings
execute 'update_notification' do
  command "sleep 15 && #{cli} setting-notification --cluster=#{cb_ip}:#{port} --enable-notification=#{updatenotification}   --user=#{user} --password=#{pass}"
  action :run
end

execute 'auto_compaction' do
  command "sleep 15 && #{cli} setting-compaction --cluster=#{cb_ip}:#{port} --compaction-db-percentage=#{autocompaction}    --user=#{user} --password=#{pass}"
  action :run
end

execute 'auto_failover' do
  command "sleep 15 && /opt/couchbase/bin/curl \"http://#{cb_ip}:#{port}/settings/autoFailover\" -i -u  #{user}:#{pass} -d \'enabled=true&timeout=#{autofailovertime}\'"
  action :run
end

execute 'email_alerts' do
  command "sleep 15 && #{cli} setting-alert --cluster=#{cb_ip}:#{port} --enable-email-alert=1  --alert-auto-failover-node --alert-auto-failover-max-reached --alert-auto-failover-node-down --alert-auto-failover-cluster-small --alert-ip-changed --alert-disk-space --alert-meta-overhead --alert-meta-oom --alert-write-failed --email-recipients=\"#{recipents}\" --email-sender=#{sender} --email-host=#{host} --email-port=#{emailport}  --user=#{user} --password=#{pass}"
  action :run
end

added_server=false
nodes.reject { |n| n[:ciAttributes][:private_ip] == cb_ip || server_list.index("#{n[:ciAttributes][:private_ip]}:#{clusport}") != nil }.each do |cluster_node|
  node_ip = cluster_node[:ciAttributes][:private_ip]
  Chef::Log.info("Queuing up server: #{node_ip}:#{clusport}")
  added_server = true

  command  = "#{cli} server-add"
  command += " -c #{cb_ip}:#{clusport}"
  command += " -u #{user} -p #{pass}"
  command += " --server-add=#{node_ip}:#{clusport}"
  command += " --server-add-username=#{user}"
  command += " --server-add-password=#{pass}"
  
  execute 'server_add' do
    command "sleep 15 && #{command}"
    action :run
  end
end

execute 'join_cluster' do
  command "sleep 15 && #{cli} rebalance -c #{cb_ip}:#{clusport} -u #{user} -p #{pass}"
  returns [0, 2]
  action :run
  only_if { added_server }
end

ruby_block 'verify_server_list' do
  block do
    server_list_ips=Array.new
    
    server_list_verify = `#{cli} server-list --cluster=#{cb_ip}:#{clusport} --user=#{user} --password=#{pass}`
    server_list_verify.each_line do |line|
      data = line.split(' ')
      server_list_ips.push(data[0].split('@')[1])
      
      if data[2] != 'healthy'
        Chef::Application.fatal!("Server #{data[1]} is not healthy, it is #{data[2]}")
      end
  
      if data[3] != 'active'
        Chef::Application.fatal!("Server #{data[1]} is not active, it is #{data[3]}")
      end
    end

    nodes.each do |cluster_node|
      node_ip = cluster_node[:ciAttributes][:private_ip]
      if ( !server_list_ips.include?(node_ip) )
        Chef::Application.fatal!("Server #{node_ip} is not part of Couchbase server list #{server_list_ips.join(',')}")
      end
    end
  end
  action :run
end
