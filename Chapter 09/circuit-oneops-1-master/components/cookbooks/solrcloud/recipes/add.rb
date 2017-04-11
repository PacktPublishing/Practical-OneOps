#
# Cookbook Name :: solrcloud
# Recipe :: add.rb
#
# The recipe stops the solrcloud on the node.
#

include_recipe 'solrcloud::default'

include_recipe 'solrcloud::solrcloud'
include_recipe 'solrcloud::deploy'
include_recipe 'solrcloud::customconfig'




# Chef::Log.info("Configure Logging")
# template "/etc/logrotate.d/solr#{node['solrmajorversion']}" do
#   	source "solr.logrotate.erb"
#   	owner "#{node['solr']['user']}"
# 	group "#{node['solr']['user']}"
#     mode '0755'
# end

# cron "logrotate" do
#   	minute '0'
#   	command "sudo /usr/sbin/logrotate /etc/logrotate.d/solr#{node['solrmajorversion']}"
#   	mailto '/dev/null'
#   	action :create
# end


