#
# Cookbook Name :: solrcloud
# Attributes :: default.rb
#


node.set['solr']['user'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /User/ }.first[:ciAttributes]['username']
node.set['user']['dir'] = "/"+node['solr']['user']

node.set['clusterstatus']['uri'] = "solr/admin/collections?action=CLUSTERSTATUS&wt=json";
node.set['clusterstatus']['uri_v6'] = "solr/admin/zookeeper?detail=true&path=%2Fcollections";
node.set['aliases_uri_v6'] = "solr/admin/zookeeper?detail=true&path=%2Faliases.json";

result = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }

if(result.any?)
	node.set['tomcat_version'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['version']
	node.set['protocol'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['protocol']
	node.set['executor_name'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['executor_name']
	node.set['enable_method_trace'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['enable_method_trace']
	node.set['server_header_attribute'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['server_header_attribute']
	node.set['ssl_port'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['ssl_port']
	node.set['advanced_connector_config'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['advanced_connector_config']
	node.set['tomcatversion'] = node['tomcat_version'][0,1];
	node.set['tomcat']['dir'] = node['user']['dir']+"/tomcat"+node['tomcatversion']
end


