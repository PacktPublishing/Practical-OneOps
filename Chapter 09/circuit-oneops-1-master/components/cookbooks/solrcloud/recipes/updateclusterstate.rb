#
# Cookbook Name :: solrcloud
# Recipe :: replacereplica.rb
#
# The recipe deletes the dead replicas updates the clusterstate to the solrcloud.
#

require 'open-uri'
require 'json'
require 'uri'


include_recipe 'solrcloud::default'

time = Time.now.getutc.to_i


if node['solr_version'].start_with? "4."
  	request_url = "http://#{node['ipaddress']}:8080/#{node['clusterstatus']['uri']}"
end


if (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "5.")
  	request_url = "http://#{node['ipaddress']}:#{node['port_no']}/#{node['clusterstatus']['uri']}"
end


if !node['zk_select'].include? "Embedded"
	ruby_block 'update_clusterstate' do
  		block do
  			begin
	        	response = open(request_url).read
	        	jsonresponse = JSON.parse(response)
	        	Chef::Log.info(request_url)
	        	if jsonresponse["cluster"]["collections"] != nil && !jsonresponse["cluster"]["collections"].empty?
	        		collectionList = jsonresponse["cluster"]["collections"].keys
	        		if collectionList != nil && !collectionList.empty?
		        		collectionList.each do |collection|
			            	shardList = jsonresponse["cluster"]["collections"][collection]["shards"].keys			            	
			           		shardList.each do |shard|
			           			downreplicalist = Array.new()
			             		replicaList = jsonresponse["cluster"]["collections"][collection]["shards"][shard]["replicas"].keys
			             		replicaList.each do |replica|
			                 		replicastate = jsonresponse["cluster"]["collections"][collection]["shards"][shard]["replicas"][replica]["state"]
			                 		downreplicalist.push(replica) if replicastate == "down"
			               		end
			               		if downreplicalist != nil && !downreplicalist.empty?
				            		downreplicalist.each do |downreplica|
				            			deletereplica_url = "#{node['solr_collection_url']}?action=DELETEREPLICA&collection=#{collection}&shard=#{shard}&replica=#{downreplica}"
		                				Chef::Log.info(deletereplica_url)
		                				deletereplica_response = open(deletereplica_url).read
				            		end
				            	end
			            	end
			        	end
			        end
		    	end
  			rescue
  				Chef::Log.error(request_url)
  				raise "Could not the retrieve the clusterstate.json"
  			ensure
  				Chef::Log.info("End of update_clusterstate execution")
			end
		end
	end
end


