#
# Cookbook Name :: solrcloud
# Recipe :: createcollection.rb
#
# The recipe create collection on the solrcloud.
#

include_recipe 'solrcloud::default'

extend SolrCloud::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
num_shards = args["NumberOfShards"]
replication_factor = args["ReplicationFactor"]
max_shards_per_node = args["MaxShardsPerNode"]
config_name = args["ConfigName"]



createCollection(node['solr_collection_url'],"#{collection_name}","#{num_shards}","#{replication_factor}","#{max_shards_per_node}","#{config_name}")


