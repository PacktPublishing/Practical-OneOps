# SparkCluster::Helper                                                                                                             
#
# This module contains helper functions for use in the entire Spark pack

module SparkCluster
  module Helper
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
    
    # Return the IP addresses of all nodes in the cluster
    #
    # RETURNS:
    # A string array containing the IP addresses of all computes in
    # the same cloud as this instance.
    #
    def get_cluster_nodes()
      thisName = ""
      if node.workorder.has_key?("rfcCi")
        thisCiName = node.workorder.rfcCi.ciName
      else
        thisCiName = node.workorder.ci.ciName
      end

      # Get the list of all masters
      masterNodes = node.workorder.payLoad.clusterSparkMasters

      # Get the list of all workers
      workerNodes = node.workorder.payLoad.clusterSparkWorkers

      # Remember the cloud ID for this component
      cloudId = cloudid_from_name(thisCiName)

      # Filter out nodes that don't have private IPs and that also don't have
      # the same cloud ID for this component
      clusterNodes = []
      masterNodes.each do |masterNode|
        next if masterNode[:ciAttributes][:private_ip].nil? || masterNode[:ciAttributes][:private_ip].empty? || (cloudId != cloudid_from_name(masterNode.ciName))

        # Remember this master
        clusterNodes.push masterNode[:ciAttributes][:private_ip]
      end

      workerNodes.each do |workerNode|
        next if workerNode[:ciAttributes][:private_ip].nil? || workerNode[:ciAttributes][:private_ip].empty? || (cloudId != cloudid_from_name(workerNode.ciName))

        # Remember this worker
        clusterNodes.push workerNode[:ciAttributes][:private_ip]
      end
    
      return clusterNodes
    end
  
    # Return the IP addresses of all client nodes
    #
    # RETURNS:
    # A string array containing the IP addresses of all client
    # computes in the same cloud as this instance.
    #
    def get_client_nodes()
      thisName = ""
      if node.workorder.has_key?("rfcCi")
        thisCiName = node.workorder.rfcCi.ciName
      else
        thisCiName = node.workorder.ci.ciName
      end

      # Get the list of all clients
      clientNodes = node.workorder.payLoad.clusterSparkClients

      # Remember the cloud ID for this component
      cloudId = cloudid_from_name(thisCiName)

      # Filter out nodes that don't have private IPs and that also don't have
      # the same cloud ID for this component
      cloudClientNodes = []
      clientNodes.each do |clientNode|
        next if clientNode[:ciAttributes][:private_ip].nil? || clientNode[:ciAttributes][:private_ip].empty? || (cloudId != cloudid_from_name(clientNode.ciName))

        # As a check, make sure the compute has "client" in the ci name
        if clientNode[:ciName].include?("client")
          # Remember this client
          cloudClientNodes.push clientNode[:ciAttributes][:private_ip]
        end
      end
  
      return cloudClientNodes
    end

    # Returns the node representing the Spark configuration for the
    # cluster.
    #
    # RETURNS:
    # The ciAttributes entry that contains the Spark settings.
    #
    def get_spark_config()
      configName = node['app_name']

      # Since the only dependency for this component is the Spark
      # workers, just take the first DependsOn entry.
      spark_config = node.workorder.payLoad.sparkConfig[0][:ciAttributes]
    end
  end
end

