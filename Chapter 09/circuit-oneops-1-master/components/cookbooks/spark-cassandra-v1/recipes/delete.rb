# Delete - Delete the Spark Cassandra connector components
#
# This recipe removes all components used for the Spark Cassandra connector.

Chef::Log.info("Running #{node['app_name']}::delete")

require File.expand_path("../spark_cassandra_helper.rb", __FILE__)

cache_path = Chef::Config[:file_cache_path] + "/spark_cassandra"

configName = node['app_name']
configNode = node[configName]

# The parent directory for all Spark files
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

connector_dir = "#{spark_dir}/connector"

# Delete the connector directory
directory connector_dir do
  action    :delete
  recursive true
end

# Delete the cache directory
directory cache_path do
  action    :delete
  recursive true
end

# Clean up the script that downloads the libraries.
file "#{spark_dir}/get_connector_libs.sh" do
  action :delete
end

# Remove the connector libraries from all workers.
# Create a tmp file to store the private key
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join

ssh_key_file = cache_path + "/" + puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
  backup false
end

# Remove the connector libraries from all workers.
ruby_block "remove_libraries" do
  block do
    this_ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]

    # Get all nodes that are in this cloud
    workerNodes = get_cloud_nodes(node.workorder.rfcCi.ciName)

    # On every node copy the connector libraries
    workerNodes.each do |worker_ip|
      # Skip the current node
      if worker_ip != this_ip
        # Remove the existing connector directory.
        `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@#{worker_ip} "if [ -d #{connector_dir} ]; then rm -rf #{connector_dir} >/dev/null; fi; if [ -d #{connector_dir}_bak ]; then rm -rf #{connector_dir}_bak >/dev/null; fi"`

        # Update the config file.
        `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{worker_ip} "sudo #{spark_dir}/fix_spark_defaults.sh driver; sudo #{spark_dir}/fix_spark_defaults.sh executor; sudo chown spark:spark #{spark_dir}/conf/spark-defaults.conf; sudo chmod 644 #{spark_dir}/conf/spark-defaults.conf"`
      end
    end

    # Fix the spark-defaults file
    `#{spark_dir}/fix_spark_defaults.sh driver; #{spark_dir}/fix_spark_defaults.sh executor; chown spark:spark #{spark_dir}/conf/spark-defaults.conf; chmod 644 #{spark_dir}/conf/spark-defaults.conf`
  end
  notifies :delete, "file[#{ssh_key_file}]", :delayed
end
