#
# Cookbook Name :: solrcloud
# Recipe :: replacenode.rb
#
# The recipe adds the replaced node to few shards based on the max no of shards per node and joins the node to the cluster.
#

require 'open-uri'
require 'json'
require 'uri'

include_recipe 'solrcloud::default'

ci = node.workorder.rfcCi.ciAttributes;

join_replace_node = ci['join_replace_node']
collection_list = ci['collection_list']


if (join_replace_node == 'true')

  ruby_block 'join_replaced_node' do
    block do

      cnames = collection_list.split(",")

      if (node['solr_version'].start_with? "4.")
        request_url = "http://#{node['ipaddress']}:8080/"+"#{node['clusterstatus']['uri']}"
        Chef::Log.info("#{request_url}")
        response = open(request_url).read
        jsonresponse = JSON.parse(response)

        aliasList = jsonresponse["cluster"]["aliases"];
        if !"#{aliasList}".empty?
          aliasList = aliasList.keys
        end

        cnames.each do |cname|
          if (!aliasList.empty?) && (aliasList.include? "#{cname}")
            collection_name = jsonresponse["cluster"]["aliases"]["#{cname}"]
          else
            collection_name = cname
          end

          maxShardsPerNode = jsonresponse["cluster"]["collections"]["#{collection_name}"]["maxShardsPerNode"]
          shardList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"].keys
          time = Time.now.getutc.to_i
          shardToReplicaCountMap = Hash.new()

          shardList.each do |shard|
            shardstate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["state"]
            if shardstate == "active"
              replicaList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"].keys
              shardToReplicaCountMap[shard] = replicaList.size
            end
          end
          shardToReplicaCountMap = shardToReplicaCountMap.sort_by { |name, count| count }

          for i in 1..Integer(maxShardsPerNode)
            shard = shardToReplicaCountMap[i - 1][0]
            begin
              addreplica_url = "#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard}&node=#{node['ipaddress']}:8080_solr"
              Chef::Log.info(addreplica_url)
              addreplica_response = open(addreplica_url).read
            rescue
              Chef::Log.error("Failed to add replica to the collection '#{collection_name}'. Collection '#{collection_name}' may not exists.")
            ensure
              puts "End of join_node execution."
            end
          end
        end
      end

      if (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "6.")

        request_url = "http://#{node['ipaddress']}:#{node['port_no']}/"+"#{node['aliases_uri_v6']}"
        Chef::Log.info("#{request_url}")
        response = open(request_url).read
        jsonresponse = JSON.parse(response)        

        aliasMap = JSON.parse(jsonresponse["znode"]["data"])
        if !"#{aliasMap}".empty?
          collaliasList = aliasMap["collection"].keys
        end

        cnames.each do |cname|
          if (!collaliasList.empty?) && (collaliasList.include? "#{cname}")
            collection_name = jsonresponse["cluster"]["aliases"]["#{cname}"]
          else
            collection_name = cname
          end

          request_url = "http://#{node['ipaddress']}:#{node['port_no']}/#{node['clusterstatus']['uri_v6']}/#{collection_name}/state.json"
          Chef::Log.info("#{request_url}")
          response = open(request_url).read
          jsonresponse = JSON.parse(response)

          coll_hash = JSON.parse(jsonresponse["znode"]["data"])
          res = coll_hash["#{collection_name}"]
          maxShardsPerNode = res["maxShardsPerNode"]
          shardList = res["shards"].keys
          shardToReplicaCountMap = Hash.new()

          shardList.each do |shard|
            shardstate = res["shards"][shard]["state"]
            if shardstate == "active"
              replicaList = res["shards"][shard]["replicas"].keys
              shardToReplicaCountMap[shard] = replicaList.size
            end
          end

          shardToReplicaCountMap = shardToReplicaCountMap.sort_by { |name, count| count }

          for i in 1..Integer(maxShardsPerNode)
            shard = shardToReplicaCountMap[i - 1][0]
            begin
              addreplica_url = "#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard}&node=#{node['ipaddress']}:#{node['port_no']}_solr"
              Chef::Log.info(addreplica_url)
              addreplica_response = open(addreplica_url).read
            rescue
              raise "Failed to add replica to the collection '#{collection_name}'. Collection '#{collection_name}' may not exists."
            ensure
              puts "End of join_node execution."
            end
          end

        end
      end

    end
  end

end




