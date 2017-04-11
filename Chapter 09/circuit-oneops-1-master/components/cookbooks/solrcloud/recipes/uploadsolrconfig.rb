#
# Cookbook Name :: solrcloud
# Recipe :: uploadsolrconfig.rb
#
# The recipe downloads the custom config from nexus and uploads to Zookeeper.
#


include_recipe 'solrcloud::default'

extend SolrCloud::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

args = ::JSON.parse(node.workorder.arglist)
customConfigJar = args["CustomConfigJar"]
customConfigName = args["CustomConfigName"]


config_dir = '';
config_jar = '';
solr_config = node['user']['dir']+"/solr-config";


if (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "6.")
  solr_config = node['user']['dir']+"/solr-config"+node['solr_version'][0,1];
end


if !customConfigJar.empty?
	if customConfigJar.include? "jar"
  		config_dir = customConfigJar.split("/").last.split(".jar").first;
	  	if !config_dir.empty?
	    	config_jar = "#{config_dir}"+".jar";
	  	end
	end
end


zkhost = node['zk_host_fqdns']

if (!customConfigName.empty?) && (!config_jar.empty?)

  extractCustomConfig(solr_config,config_jar,customConfigJar)

  downloadconfig(node['solr_version'],"#{zkhost}",customConfigName)
  uploadprodconfig(node['solr_version'],"#{zkhost}",customConfigName)
end



