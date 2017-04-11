# Update - Update the configuration
#
# This recipe updates the pack to reflect the latest values
# specified in the configuration.

Chef::Log.info("Running #{node['app_name']}::update")

include_recipe "#{node['app_name']}::add"
