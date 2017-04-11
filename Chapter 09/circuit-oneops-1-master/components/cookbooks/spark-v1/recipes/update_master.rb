# update_master - Update the Spark master node
#
# This recipe handles changing the Spark master node due to a compute replacement

# To update the Spark master, config files need to be rebuilt and copied to all
# nodes, then all services must be restarted. As long as spark.master is updated
# on every server, each node will start up properly as either a master or a worker.

Chef::Log.info("Running #{node['app_name']}::update_master")

require File.expand_path("../spark_helper.rb", __FILE__)

spark_cache_path = Chef::Config[:file_cache_path] + "/spark"

sparkInfo = get_spark_info()
configNode = sparkInfo[:config_node]
is_using_zookeeper = sparkInfo[:is_using_zookeeper]

# The parent directory for all Spark files
spark_base = configNode['spark_base']

spark_dir = "#{spark_base}/spark"

# Make sure the Spark cache dir is there
directory spark_cache_path do
  owner 'root'
  group 'root'
  mode  '0755'
end

if !is_using_zookeeper
  # tmp file to store private key
  puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join

  ssh_key_file = spark_cache_path + "/" + puuid

  file ssh_key_file do
    content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
    mode 0600
  end

  ruby_block "update_master_location" do
    block do
      this_ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]

      # Get all nodes that are in this cloud
      workerNodes = get_cloud_nodes(node.workorder.rfcCi.ciName)

      sparkMasterURL = "spark://#{this_ip}:7077"

      # On every node copy the config files and restart the services
      workerNodes.each do |worker_ip|
        # No need to do anything for the current node...the add recipe (called
        # during a replace) has already started the service
        if worker_ip != this_ip
          `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{worker_ip} "echo -n \"#{sparkMasterURL}\" | sudo tee #{spark_dir}/conf/spark.master  > /dev/null"`

          # Restart the Spark worker service on this node
          `sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{worker_ip} sudo service spark restart`
        end
      end
    end
    notifies :delete, "file[#{ssh_key_file}]", :delayed
  end
end
