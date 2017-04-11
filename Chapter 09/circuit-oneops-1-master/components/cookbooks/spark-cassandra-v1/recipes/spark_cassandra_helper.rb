# spark_cassandra_helper - Library functions
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
