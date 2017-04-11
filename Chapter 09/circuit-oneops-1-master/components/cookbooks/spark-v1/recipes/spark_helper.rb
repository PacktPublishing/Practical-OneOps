# spark_helper - Library functions
#
# These functions contain logic that is shared across multiple components.

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

# Parse the ciName to extract the instance number from it
#
# INPUT:
# ciName: The CI name to parse
#
# RETURNS:
# A string containing the numeric instance ID, or '' if no
# name was specified
#
def instanceid_from_name(ciName)
  if ciName == nil || ciName.empty?
    # There was not a name specified.  Just return nothing.
    return ''
  end

  # The instance ID is the last component of the CI name:
  #
  # basename-cloudid-instance
  #
  # Split on the '-' character and take the last component.
  # Don't count from the front since the ciName may contain
  # hyphens.
  #
  nameComponents = ciName.split('-',-1)

  instanceid = nameComponents[nameComponents.length - 1]

  return instanceid
end

# Return the IP addresses of all nodes in a specific cloud
#
# INPUT:
# ciName: The CI name of a compute
#
# RETURNS:
# A string array containing the IP addresses of all computes in the
# cloud of the referenced compute
#
def get_cloud_nodes(ciName)
  # Get the list of all nodes
  if node.workorder.payLoad.has_key?("RequiresComputes")
    allNodes = node.workorder.payLoad.RequiresComputes
  else
    allNodes = node.workorder.payLoad.computes
  end

  # Remember the cloud ID for this component
  cloudId = cloudid_from_name(ciName)

  # Filter out nodes that don't have private IPs and that also don't have
  # the same cloud ID for this component
  workerNodes = []
  allNodes.each do |thisNode|
    next if thisNode[:ciAttributes][:private_ip].nil? || thisNode[:ciAttributes][:private_ip].empty? || (cloudId != cloudid_from_name(thisNode.ciName))

    # All nodes are worker nodes
    workerNodes.push thisNode[:ciAttributes][:private_ip]
  end

  sortedWorkerNodes = workerNodes.sort

  return sortedWorkerNodes
end

# Return the instances of all nodes in a specific cloud
#
# INPUT:
# ciName: The CI name of a compute
#
# RETURNS:
# A string array containing the IP addresses of all computes in the
# cloud of the referenced compute
#
def get_cloud_instances(ciName)
  # Get the list of all nodes
  if node.workorder.payLoad.has_key?("RequiresComputes")
    allNodes = node.workorder.payLoad.RequiresComputes
  else
    allNodes = node.workorder.payLoad.computes
  end

  # Remember the cloud ID for this component
  thisCloudId = cloudid_from_name(ciName)

  # Filter out nodes that don't have private IPs and that also don't have
  # the same cloud ID for this component
  cloudNodes = []
  allNodes.each do |thisNode|
    tempCloudId = cloudid_from_name(thisNode.ciName)

    next if thisNode[:ciAttributes][:private_ip].nil? || thisNode[:ciAttributes][:private_ip].empty? || (thisCloudId != tempCloudId)

    # All nodes are worker nodes
    cloudNodes.push thisNode
  end

  return cloudNodes
end

# Get basic information related to the Spark configuration.
#
# INPUT:
#
# RETURNS:
# A hash that contains the following values:
#   is_spark_master - An indication of whether this is the Spark master
#   spark_master_ip - The IP address of the actual Spark master
#   config_node - The node that contains the configuration values
#
def get_spark_info()
  if node.workorder.payLoad.has_key?("cassDef")
    return get_spark_info_cassandra()
  else
    return get_spark_info_standalone()
  end
end

# Get basic information related to the Spark configuration
# when integrated into a Cassandra pack.
#
# INPUT:
#
# RETURNS:
# A hash that contains the following values:
#   is_spark_master - An indication of whether this is the Spark master
#   spark_master_ip - The IP address of the actual Spark master
#   config_node - The node that contains the configuration values
#
def get_spark_info_cassandra()
  # Create an empty hash...the values will be filled in
  sparkInfo = Hash.new

  configName = node['app_name']

  sparkInfo[:config_node] = node[configName]

  # Determine the list of computes in this cloud
  allNodes = nil

  if node.workorder.has_key?("rfcCi")
    allNodes = get_cloud_instances(node.workorder.rfcCi.ciName)
  else
    allNodes = get_cloud_instances(node.workorder.ci.ciName)
  end

  # Sort the computes
  sortedNodes = allNodes.sort_by { |thisNode| thisNode.ciName }

  # Make the first node in the sorted list the master
  masterNode = sortedNodes[0]
  masterName = masterNode.ciName

  Chef::Log.debug("get_spark_info_cassandra: masterName: #{masterName}")

  thisComputeName = node.workorder.payLoad.ManagedVia[0][:ciName]

  Chef::Log.debug("get_spark_info_cassandra: thisComputeName: #{thisComputeName}")

  sparkInfo[:spark_master_ip] = masterNode[:ciAttributes][:private_ip]

  Chef::Log.info("Found master IP [#{sparkInfo[:spark_master_ip]}]")

  if thisComputeName == masterName
    # This is the Spark master
    sparkInfo[:is_spark_master] = true
  else
    # This is not a Spark master
    sparkInfo[:is_spark_master] = false
  end

  # Determine the Zookeeper configuration
  sparkInfo[:is_using_zookeeper] = false
  sparkInfo[:zookeeper_url] = ""

  if !sparkInfo[:config_node][:zookeeper_servers].nil? && !sparkInfo[:config_node][:zookeeper_servers].empty?
    Chef::Log.info("Found Zookeeper servers")

    # Zookeeper servers were specified
    sparkInfo[:is_using_zookeeper] = true
    sparkInfo[:zookeeper_url] = sparkInfo[:config_node][:zookeeper_servers]
  else
    Chef::Log.info("No Zookeeper servers...creating independent cluster")
  end

  return sparkInfo
end

# Get basic information related to the Spark configuration in
# standalone mode.
#
# INPUT:
#
# RETURNS:
# A hash that contains the following values:
#   is_spark_master - An indication of whether this is the Spark master
#   spark_master_ip - The IP address of the actual Spark master
#   config_node - The node that contains the configuration values
#
def get_spark_info_standalone()
  # Create an empty hash...the values will be filled in
  sparkInfo = Hash.new

  if node.workorder.has_key?("rfcCi")
    thisCiName = node.workorder.rfcCi.ciName
  else
    thisCiName = node.workorder.ci.ciName
  end

  thisCloudId = cloudid_from_name(thisCiName)

  configName = node['app_name']

  # Assume that this is a Spark master unless dependent configurations are found
  sparkInfo[:is_spark_master] = true
  sparkInfo[:is_client_only] = false
  sparkInfo[:spark_master_ip] = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]
  sparkInfo[:config_node] = node[configName]

  dependentCiClass = "bom.oneops.1." + configName.slice(0,1).capitalize + configName.slice(1..-1)

  spark_configs=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] != dependentCiClass }
  if (!spark_configs.nil? && !spark_configs[0].nil?)
    # TODO: Need to be able to handle multiple master configurations

    Chef::Log.info("Found dependent configuration:")

    # This is not a Spark master
    sparkInfo[:is_spark_master] = false

    # The config node for the master drives the config for the workers and clients
    sparkInfo[:config_node] = spark_configs[0][:ciAttributes]

    # Find the Spark Master IP.  Look at the sparkMasters payload,
    # which has the computes for the Spark masters in this cloud
    masterCompute = nil

    if node.workorder.payLoad.has_key?("ringSparkMasters")
      masterComputes = node.workorder.payLoad.ringSparkMasters
    elsif node.workorder.payLoad.has_key?("allMasters")
      masterComputes = node.workorder.payLoad.allMasters
    else
      masterComputes = node.workorder.payLoad.sparkMasters
    end

    # Go through each master and find the one that is in this cloud.
    masterComputes.each do |thisMaster|
      if cloudid_from_name(thisMaster.ciName) == thisCloudId
        # This is the correct master
        masterCompute = thisMaster
      end
    end

    if masterCompute.nil?
      puts "***FAULT:FATAL=Master compute could not be found."
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end

    sparkInfo[:spark_master_ip] = masterCompute[:ciAttributes][:private_ip]

    Chef::Log.info("Found master IP [#{sparkInfo[:spark_master_ip]}]")

    # Check for the client only flag on the original config node
    if node[configName].has_key?('is_client_only') && node[configName]['is_client_only'] == 'true'
      Chef::Log.info("is_client_only flag set...this is a Spark client")
      sparkInfo[:is_client_only] = true
    else
      Chef::Log.info("No client flag...this is a Spark worker")
    end
  else
    if sparkInfo[:config_node].has_key?('is_client_only') && sparkInfo[:config_node]['is_client_only'] == 'true'
      Chef::Log.info("is_client_only flag set...this is a Spark client")
      sparkInfo[:is_client_only] = true
      sparkInfo[:spark_master_ip] = sparkInfo[:config_node]['spark_master']
    else
      Chef::Log.info("No dependent configuration...this is the spark master")
    end
  end

  # Determine the Zookeeper configuration
  sparkInfo[:is_using_zookeeper] = false
  sparkInfo[:zookeeper_url] = ""

  if !sparkInfo[:config_node][:zookeeper_servers].nil? && !sparkInfo[:config_node][:zookeeper_servers].empty?
    Chef::Log.info("Found Zookeeper servers")

    # Zookeeper servers were specified
    sparkInfo[:is_using_zookeeper] = true
    sparkInfo[:zookeeper_url] = sparkInfo[:config_node][:zookeeper_servers]
  else
    Chef::Log.info("No Zookeeper servers...creating independent cluster")
  end

  return sparkInfo
end

# Determines whether this recipe is being run on a Spark master.
#
# INPUT:
#
# RETURNS:
# A boolean value indicating whether this is a Spark master
#
def check_is_spark_master()
  isSparkMaster = false

  if node.workorder.payLoad.has_key?("cassDef")
    sparkInfo = get_spark_info_cassandra()

    isSparkMaster = sparkInfo[:is_spark_master]
  else
    configName = node['app_name']

    # Assume that this is a Spark master unless dependent configurations are found
    isSparkMaster = true

    # Construct the name of dependent classes to look for.
    dependentCiClass = "bom.oneops.1." + configName.slice(0,1).capitalize + configName.slice(1..-1)
    
    # See if there are any spark configurations this is dependent on.
    spark_configs=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] != dependentCiClass }
    if (!spark_configs.nil? && !spark_configs[0].nil?)
      # Dependent configurations were found, so this is not a Spark master
      isSparkMaster = false
    end
  end

  if isSparkMaster
    Chef::Log.debug("check_is_spark_master: #{node.workorder.rfcCi.ciName} IS the Spark master")
  else
    Chef::Log.debug("check_is_spark_master: #{node.workorder.rfcCi.ciName} is NOT the Spark master")
  end

  return isSparkMaster
end

# Looks up the Nexus URL and ensures that it is in the proper format
#
# RETURNS:
# A string containing the URL, or "" if it could not be found
#
def find_nexus_url()
  # Find the Nexus URL
  nexus_url = ""

  # Look in the cloud variables first to see if a value is specified
  cloud_vars = node.workorder.payLoad.OO_CLOUD_VARS
  cloud_vars.each do |var|
    if var[:ciName] == "nexus"
      nexus_url = "#{var[:ciAttributes][:value]}"
    end
  end

  if nexus_url == ""
    # The variables did not have a value...look in the services.
    cloud_name = node[:workorder][:cloud][:ciName]

    # Look in the defined services
    if (!node[:workorder][:services]["maven"].nil?)
      nexus_url = node[:workorder][:services]['maven'][cloud_name][:ciAttributes][:url]
    end
  end

  if nexus_url != ""
    # Fix it up if one was found
    nexus_url = fix_nexus_url(nexus_url)
  end

  return nexus_url
end

# Corrects the Nexus URL by ensuring that it is in the proper format
#
# INPUT:
# orig_nexus_url: The original Nexus URL
#
# RETURNS:
# A string containing the corrected URL
#
def fix_nexus_url(orig_nexus_url)
  new_nexus_url = orig_nexus_url

  Chef::Log.info("fix_nexus_url: in: #{orig_nexus_url}")

  urlArray = orig_nexus_url.split("/")

  # Expect the string to be:
  #
  # [http:|https:]//[server]
  #
  # or
  #
  # [http:|https:]//[server]/nexus
  #
  if (urlArray[0] == 'http:' || urlArray[0] == 'https:') && (urlArray[1] == '') && (urlArray.length == 3 || ((urlArray.length == 4) && (urlArray[3] == 'nexus')))
    # Make sure the URL ends with "nexus"
    new_nexus_url = urlArray[0] + "//" + urlArray[2] + "/nexus"
  end

  Chef::Log.info("fix_nexus_url: out: #{new_nexus_url}")

  return new_nexus_url
end
