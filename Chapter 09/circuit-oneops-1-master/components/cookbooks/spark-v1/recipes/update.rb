# Update - Update the configuration
#
# This recipe updates the pack to reflect the latest values
# specified in the configuration.

Chef::Log.info("Running #{node['app_name']}::update")

cache_path = Chef::Config[:file_cache_path] + "/spark"

include_recipe "#{node['app_name']}::add"
