# Repair - Repairs the Spark components.
#
# This recipe ensures that all of the Spark components are working
# properly.  In the event that any of them have been changed or are
# not functioning, they are set back to what they should be.

Chef::Log.info("Running #{node['app_name']}::repair")

# A repair ensures that all services are in the right state. This 
# can be done with a restart.
include_recipe "#{node['app_name']}::spark_restart"
