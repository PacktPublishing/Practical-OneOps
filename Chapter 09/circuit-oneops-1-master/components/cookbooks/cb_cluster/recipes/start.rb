Chef::Log.info("couchbase_cluster start action")

include_recipe 'cb_cluster::base'

unless node.workorder.payLoad.has_key? "SecuredBy"
  Chef::Log.error("unsupported, missing SecuredBy")
  return false
end

cb_cluster_cluster "exec_start_couchbase" do
  ssh_key   node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  ips     node.workorder.payLoad.ManagedVia
  action    :start_couchbase
end

