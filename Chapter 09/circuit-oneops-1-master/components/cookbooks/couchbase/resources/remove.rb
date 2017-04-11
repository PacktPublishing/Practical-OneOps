##
# process resource
#
# Removes a node from the cluster
#
# @Author Scott Boring - sboring@walmartlabs.com
##

actions :remove_nothing, :remove_single_node, :remove_cluster

attribute :cluster, :kind_of => String, :required => true
attribute :username, :kind_of => String, :required => true
attribute :password, :kind_of => String, :required => true
attribute :node, :kind_of => String, :required => true
attribute :node_platform, :kind_of => String, :required => true
