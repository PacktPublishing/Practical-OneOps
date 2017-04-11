##
# Creates data path and permission
# Initialize a couchbase node for data_path
# Set limits file
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

actions :create_data_path, :init_couchbase_data_path, :set_ulimits_file

attribute :data_path, :kind_of => String, :required => true
attribute :port, :kind_of => String, :required => true
attribute :user, :kind_of => String, :required => true
attribute :pass, :kind_of => String, :required => true
