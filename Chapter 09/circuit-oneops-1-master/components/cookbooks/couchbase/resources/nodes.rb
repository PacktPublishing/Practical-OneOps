##
# nodes resource
#
# Adds and removes nodes to the cluster
#
# @Author Scott Boring - sboring@walmartlabs.com
##

actions :update
default_action :update

attribute :cluster, :kind_of => String, :required => true
attribute :username, :kind_of => String, :required => true
attribute :password, :kind_of => String, :required => true
attribute :nodes, :kind_of => Array, :required => true
