# Distribute_libs - Distribute the downloaded libraries
#
# This recipe copies all libraries required for the Spark Cassandra
# Connector to all worker nodes.

Chef::Log.info("Running #{node['app_name']}::distribute_libs")

require File.expand_path("../spark_cassandra_helper.rb", __FILE__)

configName = node['app_name']
configNode = node[configName]

spark_cache_path = Chef::Config[:file_cache_path] + "/spark_cassandra"

# The parent directory for all Spark files
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

connector_dir = "#{spark_dir}/connector"

configFile = spark_dir + "/conf/spark-defaults.conf"

# tmp file to store private key
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join

ssh_key_file = spark_cache_path + "/" + puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
  backup false
end

# Copy the connector libraries to all workers.
ruby_block "copy_libraries" do
  block do
    this_ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]

    # Get all nodes that are in this cloud
    workerNodes = get_cloud_nodes(node.workorder.rfcCi.ciName)

    # On every node copy the connector libraries
    workerNodes.each do |worker_ip|
      # Skip the current node
      if worker_ip != this_ip
        # Rename the existing connector directory.
        `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{worker_ip} "if [ -d #{connector_dir}_bak ]; then sudo rm -rf #{connector_dir}_bak >/dev/null; fi; sudo mv #{connector_dir} #{connector_dir}_bak; sudo mkdir -p #{connector_dir}; sudo chown oneops:oneops #{connector_dir}"`

        # Copy the libraries in.
        `if [ -n "$(ls -A #{connector_dir})" ]; then scp -p -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null #{connector_dir}/* oneops@#{worker_ip}:#{connector_dir}/; fi`

        # Fix the permissions.
        `if [ -n "$(ls -A #{connector_dir})" ]; then ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{worker_ip} "sudo chmod 755 #{connector_dir}; sudo chmod 644 #{connector_dir}/*; sudo chown -R spark:spark #{connector_dir}"; fi`

        # Update the config file.
        `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{worker_ip} "sudo #{spark_dir}/fix_spark_defaults.sh driver; sudo #{spark_dir}/fix_spark_defaults.sh executor; sudo chown spark:spark #{spark_dir}/conf/spark-defaults.conf; sudo chmod 644 #{spark_dir}/conf/spark-defaults.conf"`
      end
    end

    # Fix the spark-defaults file
    `#{spark_dir}/fix_spark_defaults.sh driver; #{spark_dir}/fix_spark_defaults.sh executor; chown spark:spark #{spark_dir}/conf/spark-defaults.conf; chmod 644 #{spark_dir}/conf/spark-defaults.conf`
  end
  notifies :delete, "file[#{ssh_key_file}]", :delayed
end
