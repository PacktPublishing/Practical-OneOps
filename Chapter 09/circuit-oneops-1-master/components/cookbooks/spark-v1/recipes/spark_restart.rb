# spark_restart - Restart the Spark components
#
# This recipe restarts Spark on the server.  It will start the
# appropriate services, depending on whether this is a designated 
# Spark master.

Chef::Log.info("Running #{node['app_name']}::spark_restart")

require File.expand_path("../spark_helper.rb", __FILE__)

# Assume that this is a Spark master unless dependent configurations are found
sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]

# Restart the Spark service
service "spark" do
  action [ :restart ]
  only_if { !is_client_only }
end

# Start the Spark Thrift Server service
service  "spark-thriftserver" do
  action [ :restart ]
  only_if { is_client_only && configNode.has_key?('enable_thriftserver') && configNode['enable_thriftserver'] == 'true' }
end

# Start the Spark History Server service
service  "spark-historyserver" do
  action [ :restart ]
  only_if { is_client_only && configNode.has_key?('enable_historyserver') && configNode['enable_historyserver'] == 'true' }
end
