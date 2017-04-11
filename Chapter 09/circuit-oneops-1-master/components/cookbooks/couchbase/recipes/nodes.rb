##
# nodes recipe
#
# Adds and removes nodes to the cluster
#
# Used by the ring component
#
# @Author Scott Boring - sboring@walmartlabs.com
##

##
# Gets the IP address for nodes to be used in the cluster
##
def get_node_ips
  ips = []
  node.workorder.payLoad.ManagedVia.each do |n|
    ips.push(n[:ciAttributes]['priviate_ip'])
  end
  ips
end

##
# Gets the CouchBase component attributes
##
def get_couchbase_attributes
  array = node.workorder.payLoad.DependsOn.reject do |d|
    d['ciClassName'].split('.').last != 'Couchbase'
  end
  array.first[:ciAttributes]
end

##
 # Gets an IP address for a node that is already in the cluster
##
def get_cluster
  array = node.workorder.payLoad.ManagedVia.reject do |d|
    d['isActiveInRelease']
  end
  array.first[:ciAttributes]['private_ip']
end

cluster = get_cluster
node_ips = get_node_ips
couchbase_attributes = get_couchbase_attributes

Chef::Log.info "Nodes " + node_ips.join(", ")

##
# Calls the nodes resource to do the add/remove
##
couchbase_nodes "nodes" do
  cluster cluster
  nodes node_ips
  username couchbase_attributes[:adminuser]
  password couchbase_attributes[:adminpassword]
end

