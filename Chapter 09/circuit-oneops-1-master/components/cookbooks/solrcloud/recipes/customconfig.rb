#
# Cookbook Name :: solrcloud
# Recipe :: customconfig.rb
#
# The recipe downloads the custom config from nexus and uploads to Zookeeper
#

include_recipe 'solrcloud::default'


extend SolrCloud::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

config_dir = '';
config_jar = '';
solr_config = node['user']['dir']+"/solr-config";


if (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "6.")
  solr_config = node['user']['dir']+"/solr-config"+node['solr_version'][0,1];
end



if !node['config_url'].empty?
	if node['config_url'].include? "jar"
  		config_dir = node['config_url'].split("/").last.split(".jar").first;
	  	if !config_dir.empty?
	    	config_jar = "#{config_dir}"+".jar";
	  	end
	end
end

if (!node['custom_config_name'].empty?) && (!config_jar.empty?)

  	extractCustomConfig(solr_config,config_jar,node['config_url'])

  	downloadconfig(node['solr_version'],node['zk_host_fqdns'],node['custom_config_name'])
  	uploadprodconfig(node['solr_version'],node['zk_host_fqdns'],node['custom_config_name'])

end


