# Repair - Repairs the Spark components.
#
# This recipe ensures that all of the Spark Cassandra Connector
# components are configured properly.

Chef::Log.info("Running #{node['app_name']}::repair")

# Run the add recipe again to repair the installation.
include_recipe "#{node['app_name']}::add"
