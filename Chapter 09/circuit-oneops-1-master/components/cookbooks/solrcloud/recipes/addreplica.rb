#
# Cookbook Name :: solrcloud
# Recipe :: addReplica.rb
#
# The recipe adds replica to the solr cloud.
#

require 'json'
require 'excon'

include_recipe 'solrcloud::default'

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
shard_name = args["ShardName"]
time = Time.now.getutc.to_i

downreplicalist = ''


if (!"#{collection_name}".empty?) && (!"#{shard_name}".empty?)

	if (node['solr_version'].start_with? "4.")
    	request_url = "http://#{node['ipaddress']}:8080/#{node['clusterstatus']['uri']}"
    	response = open(request_url).read
    	jsonresponse = JSON.parse(response)
		Chef::Log.info(request_url)

		if (!jsonresponse["cluster"]["collections"].empty?) && (!jsonresponse["cluster"]["collections"]["#{collection_name}"].empty?)
      		replicaip = '';
      		maxShardsPerNode = jsonresponse["cluster"]["collections"]["#{collection_name}"]["maxShardsPerNode"]
            replicationFactor = jsonresponse["cluster"]["collections"]["#{collection_name}"]["replicationFactor"]
      		shardList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"].keys
 
            numShardExists = 0
            noofoccurences = 0
            shardList.each do |shard|
            	shardstate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["state"]
				if shardstate == "active"
					downreplicalist = Array.new()
					replicaList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"].keys
					replicaList.each do |replica|
						replicastate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"][replica]["state"]
						replicaip = replica[0,replica.index(':')]
						downreplicalist.push(replicaip) if replicastate == "down"
						if (replicaip == "#{node['ipaddress']}")
							numShardExists = numShardExists + 1 if noofoccurences == 0
							noofoccurences = noofoccurences + 1
							if (shard == shard_name)
								Chef::Log.info("Node #{replicaip} added as replica on #{shard_name}")
								if (Integer(noofoccurences) == Integer(maxShardsPerNode))
									Chef::Log.error("Node #{replicaip} reached max no of shards.")
								end
								return
							end
						end	
          			end
				end
            end
			if numShardExists < Integer(maxShardsPerNode)
      			if (downreplicalist.include? "#{node['ipaddress']}")
      				return
      			else
      				begin
      					Chef::Log.info("#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard_name}&node=#{node['ipaddress']}:8080_solr")
						bash 'add_replica' do
					    	user "#{node['solr']['user']}"
					    	code <<-EOH
					    		curl '#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard_name}&node=#{node['ipaddress']}:8080_solr'
					    	EOH
					    	not_if { "#{collection_name}".empty? }
					  	end
					rescue
						Chef::Log.error("Failed to add replica to the collection '#{collection_name}'. Collection '#{collection_name}' may not exists.")
					ensure
						puts "End of add_replica execution."
					end
      			end
      		else
  				Chef::Log.error("Node #{replicaip} exists on #{numShardExists} and reached max no of shards.")
			end
	    end
	end

	if (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "6.")

	  	request_url = "http://#{node['ipaddress']}:#{node['port_no']}/#{node['clusterstatus']['uri_v6']}/#{collection_name}/state.json"
    	response = open(request_url).read
    	jsonresponse = JSON.parse(response)
		Chef::Log.info(request_url)

		coll_hash = JSON.parse(jsonresponse["znode"]["data"])
		res = coll_hash["#{collection_name}"]

		maxShardsPerNode = res["maxShardsPerNode"]
        replicationFactor = res["replicationFactor"]
  		shardList = res["shards"].keys

        numShardExists = 0
        noofoccurences = 0
        shardList.each do |shard|
        	shardstate = res["shards"][shard]["state"]
			if shardstate == "active"
				downreplicalist = Array.new()
				replicaList = res["shards"][shard]["replicas"].keys
				replicaList.each do |replica|
					replicastate = res["shards"][shard]["replicas"][replica]["state"]
					node_name = res["shards"][shard]["replicas"][replica]["node_name"]
					replicaip = node_name[0,node_name.index(':')]
					downreplicalist.push(replicaip) if replicastate == "down"
					if (replicaip == "#{node['ipaddress']}")
						numShardExists = numShardExists + 1 if noofoccurences == 0
						noofoccurences = noofoccurences + 1
						if (shard == shard_name)
							Chef::Log.info("Node #{replicaip} added as replica on #{shard_name}")
							if (Integer(noofoccurences) == Integer(maxShardsPerNode))
								Chef::Log.error("Node #{replicaip} reached max no of shards.")
							end
							return
						end
					end
      			end
			end
        end
        if numShardExists < Integer(maxShardsPerNode)
  			if (downreplicalist.include? "#{node['ipaddress']}")
  				return
  			else
  				begin
  					Chef::Log.info("#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard_name}&node=#{node['ipaddress']}:#{node['port_no']}_solr")
					bash 'add_replica' do
				    	user "#{node['solr']['user']}"
				    	code <<-EOH
				    		curl '#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard_name}&node=#{node['ipaddress']}:#{node['port_no']}_solr'
				    	EOH
				    	not_if { "#{collection_name}".empty? }
				  	end
				rescue
					Chef::Log.error("Failed to add replica to the collection '#{collection_name}'. Collection '#{collection_name}' may not exists.")
				ensure
					puts "End of add_replica execution."
				end
  			end
  		else
  			Chef::Log.error("Node #{replicaip} exists on #{numShardExists} and reached max no of shards.")
		end
	end
else
	Chef::Log.error("Input parameters (collection_name,shard_name) are required.")
end




