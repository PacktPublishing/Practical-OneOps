# Replace - Replaces all components
#
# This recipe replaces all components used for Spark with
# the settings they are supposed to be at.

Chef::Log.info("Running #{node['app_name']}::replace")

include_recipe "#{node['app_name']}::add"

require File.expand_path("../spark_helper.rb", __FILE__)

# After doing the normal work for an add, update the master if it is necessary

# Read the Spark metadata to determine whether this compute is the Spark master
sparkInfo = get_spark_info()

if sparkInfo[:is_spark_master]
  # A master node was replaced.  The master needs to be updated.
  Chef::Log.info("This is the Spark master...updating configuration")
  
  include_recipe "#{node['app_name']}::update_master"
end
