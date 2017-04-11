#
# Cookbook Name :: solrcloud
# Recipe :: repair.rb
#
# The recipe repair the solrcloud set up on the node.
#

ci = node.workorder.ci.ciAttributes;
solr_version = ci['solr_version']
solrmajorversion = "#{solr_version}"[0,1]

if "#{solr_version}".start_with? "4."
	execute "tomcat#{node['tomcatversion']} restart" do
	  command "service tomcat#{node['tomcatversion']} restart"
	  user "#{node['solr']['user']}"
	  action :run
	  only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}")}
	end
end


if ("#{solr_version}".start_with? "5.") || ("#{solr_version}".start_with? "6.")
	execute "solr#{solrmajorversion} restart" do
	  command "service solr#{solrmajorversion} restart"
	  user "root"
	  action :run
	  only_if { ::File.exists?("/etc/init.d/solr#{solrmajorversion}")}
	end
end


