##
# cluster providers
#
# Initialize cluster
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

def whyrun_supported?
  true
end

use_inline_resources


# Calculate the per node ram quota allocation based on the total physical memory available
# and the percentage of RAM being allocated to Couchbase on each node. 
# @param ramquota_percentage_per_node: The ram quota percentage selected in the Couchbase component
def get_ram_size_mb(ramquota_percentage_per_node)

	Chef::Log.info("get_ram_size_mb: ramquota_percentage_per_node = #{ramquota_percentage_per_node} ")
	
	total_available_physical_ram = 0
	ram_quota_factor = 0.0	

	# validate ram quota percentage parameter
	if (/[0-9][0-9]%/.match(ramquota_percentage_per_node) != nil)

		if (ramquota_percentage_per_node[0,2].to_i >= 20 && ramquota_percentage_per_node[0,2].to_i <= 80)
			
			ram_quota_factor = ramquota_percentage_per_node[0,2].to_f / 100
			Chef::Log.info("get_ram_size_mb: ram_quota_factor = #{ram_quota_factor}")
			
		else
			Chef::Log.info( "get_ram_size_mb: Supplied value for #{ramquota_percentage_per_node} is outside the range of 20%-80%. Default to 80%")
			ram_quota_factor = 0.8
		end

	else
		Chef::Log.info( "get_ram_size_mb: Invalid value for ramquota_percentage_per_node = #{ramquota_percentage_per_node}. Default to 80%")
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

  
#initialize cluster
action :init_cluster do
  #start couchbase server if not running
  service "couchbase-server" do
    action :start
  end
	
  Chef::Log.info("init_cluster: with cluster ramsize = #{new_resource.per_node_ram_quota_mb}")
    
  per_node_ram_quota_mb = get_ram_size_mb(new_resource.per_node_ram_quota_mb)
  Chef::Log.info("init_cluster: per_node_ram_quota_mb = #{per_node_ram_quota_mb}")

  # Initialize cluster
  execute 'initalize_cluster' do
    command "sleep 15 && /opt/couchbase/bin/couchbase-cli cluster-init -c localhost:#{new_resource.port} --cluster-init-username=#{new_resource.user} " +
                "--cluster-init-password=#{new_resource.pass} --cluster-init-port=#{new_resource.port} -u #{new_resource.user} -p #{new_resource.pass} " +
                "--cluster-ramsize=#{per_node_ram_quota_mb}"
    action :run
  end
end

action :waiting_init_cluster do
  #Wait on init cluster
  execute 'wait_on_cluster' do
    command "sleep 30"
    action :run
  end
end

action :init_single_node_cluster do
  #start couchbase server if not running
  service "couchbase-server" do
    action :start
  end
  updatenotification=0
  if new_resource.update_notification.eql? 'true'
    updatenotification = 1
  end

  #Chef::Log.info("Availability Mode:#{new_resource.availability_mode} ")
  log "check_availability_mode" do
    message "Availability Mode:#{new_resource.availability_mode} "
    level :info
  end
  # Only for single node. Ring is used for redundant env.
  if new_resource.availability_mode == 'single'

    #Chef::Log.info("Initializing single node cluster")
    log "init single node cluster" do
      message "Initializing single node cluster"
      level :info
    end

    Chef::Log.info("init_single_node_cluster: with cluster ramsize = #{new_resource.per_node_ram_quota_mb}")

    per_node_ram_quota_mb = get_ram_size_mb(new_resource.per_node_ram_quota_mb)
    Chef::Log.info("init_single_node_cluster: per_node_ram_quota_mb = #{per_node_ram_quota_mb}")

    # Change cluster config
    execute 'cluster_init' do
      command "sleep 15 && /opt/couchbase/bin/couchbase-cli cluster-init -c localhost:#{new_resource.port} -u #{new_resource.user} -p #{new_resource.pass} --cluster-init-port=#{new_resource.port} --cluster-ramsize=#{per_node_ram_quota_mb}"
      action :run
    end

    #CB Settings
    execute 'update_notification' do
      command "sleep 15 && /opt/couchbase/bin/couchbase-cli setting-notification --cluster=localhost:#{new_resource.port} --enable-notification=#{updatenotification}   --user=#{new_resource.user} --password=#{new_resource.pass}"
      action :run
    end

    execute 'auto_compaction' do
      command "sleep 15 && /opt/couchbase/bin/couchbase-cli setting-compaction --cluster=localhost:#{new_resource.port} --compaction-db-percentage=#{new_resource.autocompaction}    --user=#{new_resource.user} --password=#{new_resource.pass}"
      action :run
    end

    execute 'auto_failover' do
      command "sleep 15 && /opt/couchbase/bin/curl \"http://localhost:#{new_resource.port}/settings/autoFailover\" -i -u  #{new_resource.user}:#{new_resource.pass} -d \'enabled=true&timeout=#{new_resource.autofailovertime}\'"
      action :run
    end

    execute 'email_alerts' do
      command "sleep 15 &&  /opt/couchbase/bin/couchbase-cli setting-alert --cluster=localhost:#{new_resource.port} --enable-email-alert=1 --alert-auto-failover-node --alert-auto-failover-max-reached --alert-auto-failover-node-down --alert-auto-failover-cluster-small --alert-ip-changed --alert-disk-space --alert-meta-overhead --alert-meta-oom --alert-write-failed  --email-recipients=#{new_resource.recipents} --email-sender=#{new_resource.sender} --email-host=#{new_resource.host} --email-port=#{new_resource.emailport}  --user=#{new_resource.user} --password=#{new_resource.pass}"
      action :run
    end
  end
end
