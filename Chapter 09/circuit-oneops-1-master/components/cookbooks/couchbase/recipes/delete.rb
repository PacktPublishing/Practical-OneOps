include_recipe "couchbase::base"

cluster = Chef::Recipe::Cluster.new(node)

rmv_action = cluster.getAction
ausername = node.couchbase[:adminuser]
apassword = node.couchbase[:adminpassword]
platform = node.platform

log "remove_action" do
  message "Removing #{rmv_action}"
  level :info
end

couchbase_remove "#{rmv_action}" do
  cluster "localhost"
  node cluster.ip
  username ausername
  password apassword
  node_platform platform
  action :"#{rmv_action}"
end
