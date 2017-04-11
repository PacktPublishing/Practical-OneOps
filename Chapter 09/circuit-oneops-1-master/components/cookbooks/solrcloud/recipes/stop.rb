#
# Cookbook Name :: solrcloud
# Recipe :: stop.rb
#
# The recipe stops the solrcloud on the node.
#

ci = node.workorder.ci.ciAttributes;
solr_version = ci['solr_version']
solrmajorversion = "#{solr_version}"[0,1]

if "#{solr_version}".start_with? "4."
	service "tomcat#{node['tomcatversion']}" do
    	supports :status => true, :restart => true, :start => true
    	action :stop
	end
end

if ("#{solr_version}".start_with? "5.") || ("#{solr_version}".start_with? "6.")
	service "solr#{solrmajorversion}" do
    	supports :status => true, :restart => true, :start => true
    	action :stop
	end
end

