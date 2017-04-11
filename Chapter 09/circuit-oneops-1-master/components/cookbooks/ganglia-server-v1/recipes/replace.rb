# Replace - Replaces all components
#
# This recipe is called when the compute that Ganglia has been
# running on has been replaced.

Chef::Log.info("Running #{node['app_name']}::replace")

include_recipe "#{node['app_name']}::add"
