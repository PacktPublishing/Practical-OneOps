#
# Cookbook Name :: solrcloud
# Recipe :: updatesolrconfig.rb
#
# The recipe updates the solr-config and uploads to Zookeeper.
#


include_recipe 'solrcloud::default'

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["collection_name"]
common_property = args["common_property"]
value = args["value"]


if (!"#{collection_name}".empty?) && (!"#{common_property}".empty?)
	if (!"#{value}".empty?)
		cmd_login = "curl -X POST -H 'Content-type:application/json' -d '{'set-property' : {'#{common_property}':#{value}}}' 'http://#{node['ipaddress']}:8983/solr/#{collection_name}/config'"
	    Chef::Log.info("#{cmd_login}")
	    parsed = ''

	    begin
	    	cmd = `#{cmd_login}`
			parsed = JSON.parse(cmd)
		rescue
			Chef::Log.error("Failed to execute rest call")
		ensure
			puts "End of rest call execution."
		end

		if (parsed["errorMessages"] != nil)
			parsed["errorMessages"].each do |error|
				Chef::Log.error(error)
			end
			Chef::Log.error("Failed to set #{common_property} on the collection '#{collection_name}'.")
		end
	else
		cmd_login = "curl -X POST -H 'Content-type:application/json' -d '{'unset-property' : {'#{common_property}'}}' 'http://#{node['ipaddress']}:8983/solr/#{collection_name}/config'"
	    Chef::Log.info("#{cmd_login}")
	    parsed = ''

	    begin
	    	cmd = `#{cmd_login}`
			parsed = JSON.parse(cmd)
		rescue
			Chef::Log.error("Failed to execute rest call")
		ensure
			puts "End of rest call execution."
		end

		if (parsed["errorMessages"] != nil)
			parsed["errorMessages"].each do |error|
				Chef::Log.error(error)
			end
			Chef::Log.error("Failed to unset #{common_property} on the collection '#{collection_name}'.")
		end
	end
end


