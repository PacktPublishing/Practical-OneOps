#
# Cookbook Name :: solrcloud
# Recipe :: restart.rb
#
# The recipe restarts the solrcloud on the node.
#

ci = node.workorder.ci.ciAttributes;
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
