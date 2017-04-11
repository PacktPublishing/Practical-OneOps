# Replace - Replaces all components
#
# This recipe replaces all resources used by the Spark_cluster
# component.

Chef::Log.info("Running #{node['app_name']}::replace")

include_recipe "#{node['app_name']}::add"

