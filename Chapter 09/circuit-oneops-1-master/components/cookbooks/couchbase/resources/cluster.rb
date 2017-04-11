##
# Initialize cluster
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

actions :init_cluster, :waiting_init_cluster, :init_single_node_cluster

attribute :port, :kind_of => String, :required => true
attribute :user, :kind_of => String, :required => true
attribute :pass, :kind_of => String, :required => true
attribute :update_notification, :kind_of => String, :required => true
attribute :autocompaction, :kind_of => String, :required => true
attribute :autofailovertime, :kind_of => String, :required => true
attribute :recipents, :kind_of => String, :required => true
attribute :sender, :kind_of => String, :required => true
attribute :host, :kind_of => String, :required => true
attribute :emailport, :kind_of => String, :required => true
attribute :availability_mode, :kind_of => String, :required => true
attribute :per_node_ram_quota_mb, :kind_of => String, :required => true
