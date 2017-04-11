#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: gmond
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# install gmond
package 'ganglia-gmond'

# default config for ganglia gmond
cookbook_file "/etc/ganglia/gmond.conf" do
    source "gmond.conf"
    owner "root"
    group "root"
    mode "0644"
end

# define ganglia_servers here:
ganglia_servers = cia["ganglia_servers"].split(',')

# ganglia config for yarn
template "/etc/ganglia/conf.d/yarn-gmond.conf" do
    source "yarn-gmond.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables :ganglia_servers => ganglia_servers
    notifies :restart, "service[gmond]"
end

# add gmond to chkconfig and start service
service "gmond" do
    action [:start, :enable]
    supports :restart => true, :reload => true
end
