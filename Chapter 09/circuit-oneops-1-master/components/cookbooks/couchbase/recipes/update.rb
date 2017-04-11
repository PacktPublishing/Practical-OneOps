
include_recipe "couchbase::base"

Couchbase::Component::CouchbaseComponent.new(node).validate

include_recipe "couchbase::add"
