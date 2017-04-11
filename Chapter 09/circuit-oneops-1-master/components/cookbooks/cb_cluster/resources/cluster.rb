##
# Initialize cluster
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

actions :start_couchbase, :stop_couchbase

attribute :ssh_key, :kind_of => String, :required => true
attribute :ips, :kind_of => Array, :required => true
attribute :username, :kind_of => String, :required => true
attribute :password, :kind_of => String, :required => true
attribute :port, :kind_of => String, :required => true
