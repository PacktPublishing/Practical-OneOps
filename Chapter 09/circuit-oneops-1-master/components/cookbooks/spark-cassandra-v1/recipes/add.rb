# Add - Add the Spark Cassanda Connector components
#
# This recipe installs all of the components that are required for
# the Spark Cassandra Connector

Chef::Log.info("Running #{node['app_name']}::add")

# Download the libraries
include_recipe "#{node['app_name']}::cass_connector_libs"

# Distribute the libraries to all workers
include_recipe "#{node['app_name']}::distribute_libs"

Chef::Log.info("#{node['app_name']}::add completed")
