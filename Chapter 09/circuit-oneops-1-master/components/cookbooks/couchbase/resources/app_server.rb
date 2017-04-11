##
# Gets the installer pack from the Repo
# Executes prerequisites to install NOSQL application server
# Installs application server
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

actions :prerequisites, :download_install_couchbase

attribute :version, :kind_of => String, :required => true
attribute :edition, :kind_of => String, :required => true
attribute :arch, :kind_of => String, :required => true
attribute :distributionurl, :kind_of => String, :required => true
attribute :sha256, :kind_of => String, :required => true
attribute :cloud_name, :kind_of => String, :required => true
attribute :cookbook_name, :kind_of => String, :required => true
attribute :availability_mode, :kind_of => String, :required => true
attribute :comp_mirrors, :kind_of => String, :required => true
attribute :cloud_mirrors, :kind_of => String, :required => true
attribute :src_mirror, :kind_of => String, :required => true
attribute :node_platform, :kind_of => String, :required => true
attribute :upgradecouchbase, :kind_of => String, :required =>true
attribute :replace_node, :kind_of => String
