#
# Cookbook Name :: solrcloud
# Recipe :: default.rb
#
# The recipe sets the variable.
#

extend SolrCloud::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

begin
	if node.workorder.ci != nil
		ci = node.workorder.ci.ciAttributes;
	end
rescue
ensure
end

begin
	if node.workorder.rfcCi != nil
		ci = node.workorder.rfcCi.ciAttributes;
	end
rescue
ensure
end


node.set["zk_select"] = ci['zk_select']
node.set["num_instances"] = ci['num_instances']
node.set["port_num_list"] = ci['port_num_list']
node.set["platform_name"] = ci['platform_name']
node.set["env_name"] = ci['env_name']
node.set['solrcloud']['cloud_ring'] = ci['cloud_ring']
node.set['solrcloud']['datacenter_ring'] = ci['datacenter_ring']
node.set['solrcloud']['replace_nodes'] = ci['replace_nodes']


# fqdn = "#{hostname}".split('.',3 ).last
# node.set["zk_host_fqdns"] = "#{node['platform_name']}.#{node['env_name']}.#{fqdn}"

setZkhostfqdn(node['zk_select'],ci)

node.set['solr_version'] = ci['solr_version']
node.set['solrmajorversion'] = "#{node['solr_version']}"[0,1]

node.set["config_name"] = ci['config_name']
node.set["custom_config_name"] = ci['custom_config_name']
node.set["port_no"] = ci['port_no']

node.set['config_url'] = ci['custom_config_url']

node.set["installation_dir_path"] = ci['installation_dir_path']
node.set["data_dir_path"] = ci['data_dir_path']+"#{node['solrmajorversion']}"
node.set["gc_tune_params"] = ci['gc_tune_params']
node.set["gc_log_params"] = ci['gc_log_params']
node.set["solr_opts_params"] = ci['solr_opts_params']
node.set["solr_mem_max"] = ci['solr_max_heap']
node.set["solr_mem_min"] = ci['solr_min_heap']



if node['solr_version'].start_with? "4."
  	node.set['solr_collection_url'] = "http://#{node['ipaddress']}:8080/solr/admin/collections"
  	node.set['solr_core_url'] = "http://#{node['ipaddress']}:8080/solr/admin/cores"
  	node_solr_portnum = "8080"
end


if (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "5.")
	node.set['solr_collection_url'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/collections"
  	node.set['solr_core_url'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/cores"
  	node_solr_portnum = ci['port_no']
end



nodeip = "#{node['ipaddress']}"
node_solr_version = ci['solr_version']


puts "***RESULT:nodeip="+nodeip
puts "***RESULT:node_solr_version="+node_solr_version
puts "***RESULT:node_solr_portnum="+node_solr_portnum

