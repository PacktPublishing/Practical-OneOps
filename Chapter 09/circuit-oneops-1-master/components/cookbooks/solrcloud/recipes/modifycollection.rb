#
# Cookbook Name :: solrcloud
# Recipe :: modifycollection.rb
#
# The recipe modifies collection on the solrcloud.
#

include_recipe 'solrcloud::default'

extend SolrCloud::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
autoAddReplicas = args["AutoAddReplicas"]
replication_factor = args["ReplicationFactor"]
max_shards_per_node = args["MaxShardsPerNode"]



modifyCollection(node['solr_collection_url'],"#{collection_name}","#{autoAddReplicas}","#{replication_factor}","#{max_shards_per_node}")

