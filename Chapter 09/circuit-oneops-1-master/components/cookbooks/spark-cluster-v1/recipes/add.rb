# Spark - Spark cluster level code.
#
# This recipe contains the code that is run at the cluster level
# in a Spark deployment.

Chef::Log.info("Running spark-cluster::add")

# Parse the ciName to extract the cloud ID from it
#
# INPUT:
# ciName: The CI name to parse
#
# RETURNS:
# A string containing the numeric cloud ID, or '' if no
# name was specified
#
def cloudid_from_name(ciName)
  if ciName == nil || ciName.empty?
    # There was not a name specified.  Just return nothing.
    return ''
  end

  # The cloud ID is the second component of the CI name:
  #
  # basename-cloudid-instance
  #
  # Split on the '-' character and take the second to last component
  #
  nameComponents = ciName.split('-',-1)

  cloudid = nameComponents[nameComponents.length - 2]

  return cloudid
end


# Set the dns_record attribute to the IP of the master node
dns_record = ""

if node.workorder.has_key?("rfcCi")
  thisCloudId = cloudid_from_name(node.workorder.rfcCi.ciName)
else
  thisCloudId = cloudid_from_name(node.workorder.ci.ciName)
end

if node.workorder.payLoad.has_key?("clusterSparkMasters")
  masterList = node.workorder.payLoad.clusterSparkMasters
  masterList.each do |thisMaster|
    masterCloudId = cloudid_from_name(thisMaster[:ciName])

    if masterCloudId == thisCloudId
      # This is the master for this cloud.  The dns_record should
      # reflect it.
      dns_record = thisMaster[:ciAttributes][:private_ip]
    end
  end

  puts "***RESULT:dns_record=#{dns_record}"
else
  Chef::Log.debug("CLUSTER: clusterSparkMasters not defined...unable to set DNS record for Spark Master")
end

# If there is a Zookeeper cluster specified, perform a delayed start
# of the cluster. Look at the clusterSparkMasters payload, which contains
# all of the Spark masters in this deployment.  If all IPs are
# specified, then this is the last cluster component being deployed,
# and the actual Spark master URI (which requires the IPs of all Spark
# masters) can be constructed.

# Remember the current action name
if node.workorder.has_key?("rfcCi")
  actionName = node.workorder.rfcCi.rfcAction
else
  actionName = node.workorder.actionName
end

# Determine if Zookeeper is specified
is_zk_specified = false

spark_config=node.workorder.payLoad.sparkConfig
if spark_config != nil && spark_config[0] != nil
  Chef::Log.info("CLUSTER: Found a Spark config #{spark_config[0][:ciClassName]}")

  if !spark_config[0][:ciAttributes][:zookeeper_servers].nil? && !spark_config[0][:ciAttributes][:zookeeper_servers].empty?
    is_zk_specified = true
  end
end

if is_zk_specified || (actionName == "replace") || (actionName == "update")
  # Perform a delayed start of the Spark clusters

  # Check Spark masters to see if they all have IPs
  allMasters = node.workorder.payLoad.clusterSparkMasters

  have_all_masters = true

  allMasters.each do |thisMaster|
    if thisMaster[:ciAttributes][:private_ip].nil? || thisMaster[:ciAttributes][:private_ip].empty?
      have_all_masters = false
      break
    end
  end

  if have_all_masters || (actionName == "replace")
    # The IP addresses of all Spark masters are known.

    # Create the full Spark Master URL
    sparkMasterURL = "spark://"

    allMasters.each do |thisMaster|
      if !sparkMasterURL.end_with? "/"
        sparkMasterURL = sparkMasterURL + ","
      end

      sparkMasterURL = sparkMasterURL + thisMaster[:ciAttributes][:private_ip]

      # Use port 7077 as a default.  This would need to be read
      # from the configuration in case it becomes configurable
      sparkMasterURL = sparkMasterURL + ":7077"
    end

    Chef::Log.debug("is_zk_specified: #{is_zk_specified}")

    # Create a temp file to store private key
    puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join

    ssh_key_file = Chef::Config[:file_cache_path] + "/" + puuid

    file ssh_key_file do
      content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
      mode 0600
    end

    ruby_block "start_masters_and_workers" do
      block do
        restartedClouds = Set.new

        # SSH to each master and start it.  Build the spark.master file and start the service
        allMasters.each do |thisMaster|
          masterIP = thisMaster[:ciAttributes][:private_ip]

          nameComponents = thisMaster[:ciName].split('-',-1)

          cloudid = nameComponents[nameComponents.length - 2]

          thisMasterURL = sparkMasterURL

          thisMasterAction = thisMaster.has_key?("rfcAction") ? thisMaster.rfcAction : "";

          # This master should be started if:
          # Action ADD: This is a zookeeper installation (non-zookeeper installations are handled as the Spark components are deployed)
          # Action REPLACE: The master was replaced.

          if (is_zk_specified && ((actionName == "add") || (thisMasterAction == "add") || (thisMasterAction == "update"))) || (thisMasterAction == "replace")
            Chef::Log.debug("Starting master on #{masterIP} with master URL #{thisMasterURL}")

            # Echo the spark master URL to this server
            `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{masterIP} "echo -n \"#{thisMasterURL}\" | sudo tee /opt/spark/conf/spark.master > /dev/null"`

            # Restart the Spark master service on this node
            `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{masterIP} "sudo service spark restart"`

            # Track this cloud as a cloud with its master restarted
            restartedClouds.add cloudid
          else
            Chef::Log.debug("Skipping master on #{masterIP} [#{thisMasterAction}]")
          end
        end

        # SSH to each worker and start it.  Build the spark.master file and start the service
        allWorkers = node.workorder.payLoad.clusterSparkWorkers

        allWorkers.each do |thisWorker|
          workerIP = thisWorker[:ciAttributes][:private_ip]

          nameComponents = thisWorker[:ciName].split('-',-1)

          cloudid = nameComponents[nameComponents.length - 2]

          thisMasterURL = sparkMasterURL

          thisWorkerAction = thisWorker.has_key?("rfcAction") ? thisWorker.rfcAction : "";

          # Start this worker if its corresponding cloud has been
          # restarted or if the worker has been replaced or added.
          if (restartedClouds.include? cloudid) || ((actionName == "add") || (thisWorkerAction == "replace") || (thisWorkerAction == "add") || (thisWorkerAction == "update"))
            Chef::Log.debug("Starting worker on #{workerIP} with master URL #{thisMasterURL}")

            # Echo the spark master URL to this server
            `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{workerIP} "echo -n \"#{thisMasterURL}\" | sudo tee /opt/spark/conf/spark.master  > /dev/null"`

            # Restart the Spark worker service on this node
            `ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{workerIP} "sudo service spark restart"`
          else
            Chef::Log.debug("Skipping worker on #{workerIP} [#{thisWorkerAction}]")
          end
        end
      end
      notifies :delete, "file[#{ssh_key_file}]", :delayed
    end
  else
    Chef::Log.info("All masters not specified...skipping")
  end
else
  Chef::Log.info("CLUSTER: Not a Zookeeper installation...skipping delay start")
end

Chef::Log.info("Finished spark-cluster::add")
