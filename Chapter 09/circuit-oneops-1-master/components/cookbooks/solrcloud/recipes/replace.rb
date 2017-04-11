#
# Cookbook Name :: solrcloud
# Recipe :: replace.rb
#
# The recipe sets up the solrcloud on the replaced node.
#

include_recipe 'solrcloud::default'

include_recipe 'solrcloud::solrcloud'
include_recipe 'solrcloud::deploy'
include_recipe 'solrcloud::customconfig'


ci = node.workorder.rfcCi.ciAttributes;
solr_version = ci['solr_version']
solrmajorversion = "#{solr_version}"[0,1]


if "#{solr_version}".start_with? "4."
	service "tomcat#{node['tomcatversion']}" do
    	supports :status => true, :restart => true, :start => true
    	action :restart
	end
end

if ("#{solr_version}".start_with? "5.") || ("#{solr_version}".start_with? "6.")
	service "solr#{solrmajorversion}" do
    	supports :status => true, :restart => true, :start => true
    	action :restart
	end
end


include_recipe 'solrcloud::replacenode'


