##
# nodes providers
#
# Adds and removes nodes to the cluster
#
# @Author Scott Boring - sboring@walmartlabs.com
##

def whyrun_supported?
  true
end

use_inline_resources

##
# Updates the cluster by adding and removing nodes
##
action :update do
  #start couchbase server if not running
  service "couchbase-server" do
    action :start
  end

  Chef::Log.info "Cluster: " + new_resource.cluster
  Chef::Log.info "Username: " + new_resource.username
  Chef::Log.info "Nodes: " + new_resource.nodes.join(", ")

  existing_nodes = get_existing_nodes

  Chef::Log.info "Existing Nodes: " + existing_nodes.join(", ")

  nodes_to_add = new_resource.nodes.reject { |n| existing_nodes.include? n }

  known_nodes = ""

  existing_nodes.each do |n|
    known_nodes += "ns_1@" + n + ","
  end

  nodes_to_add.each do |n|
    Chef::Log.info "Adding " + n
    result = `curl -u #{new_resource.username}:#{new_resource.password} #{new_resource.cluster}:8091/controller/addNode -d "hostname=#{n}&user=#{new_resource.username}&password=#{new_resource.password}"`
    known_nodes += "ns_1@" + n + ","
    Chef::Log.info result
  end

  Chef::Log.info "Known nodes: " + known_nodes

  # Rebalance
  result = `curl -v -u #{new_resource.username}:#{new_resource.password} -X POST "http://#{new_resource.cluster}:8091/controller/rebalance" -d "ejectedNodes=&knownNodes=#{known_nodes}"`

  Chef::Log.info result

  if $?.to_i == 0
    new_resource.updated_by_last_action(true)
  else
    new_resource.updated_by_last_action(false)
    Chef::Application.fatal! "Failed to update nodes"
  end

end

##
# Gets the existing nodes from the cluster
##
def get_existing_nodes

  command = "/opt/couchbase/bin/couchbase-cli server-list"
  command += " -c #{new_resource.cluster}:8091 "
  command += " -u #{new_resource.username}"
  command += " -p #{new_resource.password}"

  results = `#{command}`

  Chef::Log.info results

  nodes_info = results.split("\n")
  existing_nodes = []

  nodes_info.each do |node_info|
    ip = node_info.split(" ")[1]
    ip = ip.split(":")[0]
    existing_nodes.push(ip)
  end

  existing_nodes

end
