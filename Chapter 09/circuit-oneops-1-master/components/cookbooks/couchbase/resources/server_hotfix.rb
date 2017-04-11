##
# Apply couchbase server hotfixes
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

actions :apply_220_hotfix

attribute :version, :kind_of => String, :required => true
attribute :sha256, :kind_of => String, :required => true
attribute :cbhotfix_220_url, :kind_of => String, :required => true
attribute :user, :kind_of => String, :required => true
attribute :pass, :kind_of => String, :required => true
attribute :port, :kind_of => String, :required => true
