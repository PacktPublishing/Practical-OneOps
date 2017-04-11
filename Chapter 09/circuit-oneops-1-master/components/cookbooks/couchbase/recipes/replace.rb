#
# Kloopz 2013 - All Rights Reserved - Do not distribute
#

ci = node.workorder.rfcCi.ciAttributes
cloud_name = node.workorder.cloud.ciName
cookbook_name = node.app_name.downcase
final_version = ci['version']
final_edition = 'enterprise'

if (ci['version'].include?('community'))
  final_version = ci['version'].gsub('community_','')
  final_edition = 'community'
end

couchbase_app_server "execute_prerequisites" do
  action :prerequisites
end

#a_cloud_mirrors = ci['binary_dist'] if !(cloud_name.to_s.empty?)
a_cloud_mirrors = node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors] if !(cloud_name.to_s.empty?)


couchbase_app_server "download_pack_install_couchbase" do
  version           final_version
  edition           final_edition
  arch              ci['arch']
  sha256            ci['checksum']
  distributionurl   ci['distributionurl']
  cloud_name        node.workorder.cloud.ciName
  cookbook_name     node.app_name.downcase
  availability_mode node.workorder.box.ciAttributes.availability
  comp_mirrors      node.send(cookbook_name).mirrors
  cloud_mirrors     a_cloud_mirrors
  src_mirror        node[cookbook_name][:src_mirror]
  node_platform     node.platform
  upgradecouchbase  ci['upgradecouchbase']
  replace_node      "true"
  action :download_install_couchbase
end

couchbase_node "create_couchbase_data_path" do
  data_path ci['datapath']
  action :create_data_path
end

couchbase_node "init_couchbase_node_data_path" do
  data_path ci['datapath']
  user      ci['adminuser']
  pass      ci['adminpassword']
  port      ci['port']
  action :init_couchbase_data_path
end

couchbase_node "set_ulimits_file" do
  action :set_ulimits_file
end

couchbase_cluster "initialize_cluster" do
  user      		ci['adminuser']
  pass      		ci['adminpassword']
  port      		ci['port']
  per_node_ram_quota_mb	ci['pernoderamquotamb']
  action :init_cluster
end

couchbase_cluster "waiting_on_init_cluster" do
  action :waiting_init_cluster
end

couchbase_server_hotfix "apply_cb_hotfix_220" do
  version           final_version
  sha256            ci['checksum']
  cbhotfix_220_url  node["couchbase"]["cbhotfix_220_url"]
  user              ci['adminuser']
  pass              ci['adminpassword']
  port              ci['port']
  action :apply_220_hotfix
end

couchbase_cluster "initialize_single_cluster_node" do
  user                  ci['adminuser']
  pass                  ci['adminpassword']
  port                  ci['port']
  update_notification   ci['updatenotification']
  autofailovertime      ci['autofailovertime']
  autocompaction        ci['autocompaction']
  recipents             ci['recipents']
  sender                ci['sender']
  host                  ci['host']
  emailport             ci['emailport']
  availability_mode     node.workorder.box.ciAttributes.availability
  per_node_ram_quota_mb	ci['pernoderamquotamb']
  action :init_single_node_cluster
end
