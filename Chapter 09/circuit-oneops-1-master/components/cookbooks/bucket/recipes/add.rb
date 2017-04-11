include_recipe 'bucket::base'
include_recipe 'couchbase::base'

Couchbase::Component::BucketComponent.new(node).add
