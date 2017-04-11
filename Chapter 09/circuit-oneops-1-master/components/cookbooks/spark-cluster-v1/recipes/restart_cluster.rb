# restart_cluster - Restart a Spark cluster
#
# This recipe restarts all components for a Spark cluster.

Chef::Log.info("Running #{node['app_name']}::restart_cluster")

# Use the helper functions from the SparkCluster::Helper library
Chef::Recipe.send(:include, SparkCluster::Helper)

spark_cache_path = Chef::Config[:file_cache_path] + "/spark"

# Make sure the Spark cache dir is there
directory spark_cache_path do
  owner 'root'
  group 'root'
  mode  '0755'
end

# Get the list of all cluster nodes.  This method will filter out
# any nodes that are not in the same cloud as this instance.
clusterNodes = get_cluster_nodes()

# Get the list of all client nodes.  This method will filter out
# any nodes that are not in the same cloud as this instance.
clientNodes = get_client_nodes()

# Generate the SSH key file
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join

ssh_key_file = spark_cache_path + "/" + puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
end

ruby_block "restart_spark" do
  block do
    # Connect to each compute and restart the services
    clusterNodes.each do |node_ip|
      Chef::Log.info("Restarting spark service on #{node_ip}...")

      # Restart the Spark service on this node
      `sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{node_ip} sudo service spark restart`
    end
  end
  notifies :delete, "file[#{ssh_key_file}]", :delayed
end

# If the thrift server is enabled, connect to the client compute and restart it
spark_config = get_spark_config()

if spark_config.has_key?('enable_thriftserver') && (spark_config['enable_thriftserver'] == 'true')
  
  # Restart the thrift server
  ruby_block "restart_thriftserver" do
    block do
      # Connect to each compute and restart the services
      clientNodes.each do |client_ip|
        Chef::Log.info("Restarting Spark thrift server service on #{client_ip}...")

        # Restart the Spark service on this node
        `sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{client_ip} sudo service spark-thriftserver restart`
      end
    end
    notifies :delete, "file[#{ssh_key_file}]", :delayed
  end
else
  Chef::Log.info("Thrift server not configured")
end

Chef::Log.info("#{node['app_name']}::restart_cluster completed")
