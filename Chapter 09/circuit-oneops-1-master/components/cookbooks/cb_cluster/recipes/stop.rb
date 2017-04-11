Chef::Log.info("couchbase_cluster stop action")

include_recipe 'cb_cluster::base'

unless node.workorder.payLoad.has_key? "SecuredBy"
  Chef::Log.error("unsupported, missing SecuredBy")
  return false
end

Chef::Log.info("Username: #{node.couchbase[:user]} Password: #{node.couchbase[:pass]}")

cb_cluster_cluster "exec_stop_couchbase" do
  ssh_key   node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  ips     node.workorder.payLoad.ManagedVia
  username  node.couchbase[:user]
  password  node.couchbase[:pass]
  port      node.couchbase[:port]
  action    :stop_couchbase
end
