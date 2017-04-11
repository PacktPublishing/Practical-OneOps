#
# Cookbook Name :: solrcloud
# Recipe :: updatemanagedschema.rb
#
# The recipe updates managed schema and uploads to Zookeeper.
#

include_recipe 'solrcloud::default'

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["collection_name"]
modify_schema_action = args["modify_schema_action"]
payload = args["payload"]
updateTimeoutSecs = args["updateTimeoutSecs"]


if (!"#{collection_name}".empty?) && (!"#{modify_schema_action}".empty?) && (!"#{payload}".empty?)
	payload_arr = payload.split('},{')
	payloadobj = ""
	if !payload_arr.empty?
		payload_arr.each do |payload|
		  	if (payload.start_with? "{")
				construct_str = "add-field:"+payload+"}"
				if (!payloadobj.empty?)
					payloadobj = payloadobj + "," + construct_str
				else
					payloadobj = construct_str
				end
			else
				if (payload.end_with? "}")
					construct_str = "add-field:"+"{"+payload
					if (!payloadobj.empty?)
						payloadobj = payloadobj + "," + construct_str
					else
						payloadobj = construct_str
					end
				else
					construct_str = "add-field:"+"{"+payload+"}"
					if (!payloadobj.empty?)
						payloadobj = payloadobj + "," + construct_str
					else
						payloadobj = construct_str
					end
			  	end
			end
		end
	else
		payloadobj = payload
	end

	cmd_login = "curl -X POST -H 'Content-type:application/json' --data-binary '{#{payloadobj}}' 'http://#{node['ipaddress']}:8983/solr/#{collection_name}/schema'"
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

	if (parsed["errors"] != nil)
		parsed["errors"].each do |error|
			Chef::Log.error(error)
		end
		Chef::Log.error("Failed to execute #{modify_schema_action} on the collection '#{collection_name}'.")
	end
end



