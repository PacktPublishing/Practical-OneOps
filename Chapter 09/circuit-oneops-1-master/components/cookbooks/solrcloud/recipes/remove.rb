#
# Cookbook Name :: solrcloud
# Recipe :: remove.rb
#
# The recipe deletes the solrcloud set up on the node marked for deletion.
#

if node['solr_version'].start_with? "4."
	execute "tomcat#{node['tomcatversion']} stop" do
	  command "service tomcat#{node['tomcatversion']} stop"
	  user node['solr']['user']
	  action :run
	  only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}")}
	end

	["/app"].each { |dir|
		Chef::Log.info("deleting #{dir} for user app")
	  	directory dir do
	    	owner node['solr']['user']
	    	group node['solr']['user']
	    	mode "0755"
	    	recursive true
	    	action :delete
	  	end
	}

	file "/etc/init.d/tomcat#{node['tomcatversion']}" do
		action :delete
	end
end

if node['solr_version'].start_with? "5." || node['solr_version'].start_with? "6."
	execute "solr#{node['solrmajorversion']} stop" do
	  command "service solr#{node['solrmajorversion']} stop"
	  user "root"
	  action :run
	  only_if { ::File.exists?("/etc/init.d/solr#{solrmajorversion}")}
	end

	[node['installation_dir_path']/solr"#{node['solrmajorversion']}" ,node['data_dir_path'],"/app",node['installation_dir_path']/"solr-#{node['solr_version']}"].each { |dir|
		Chef::Log.info("deleting #{dir} for user app")
	  	directory dir do
	    	owner node['solr']['user']
	    	group node['solr']['user']
	    	mode "0755"
	    	recursive true
	    	action :delete
	  	end
	}

	link "node['installation_dir_path']/solr#{node['solrmajorversion']}" do
	  link_type :symbolic
	  action :delete
	end

	file "/etc/init.d/solr#{node['solrmajorversion']}" do
		action :delete
	end
end

