# spark_stop - Stop the Spark components
#
# This recipe stops all Spark services on the server.

Chef::Log.info("Running #{node['app_name']}::spark_stop")

require File.expand_path("../spark_helper.rb", __FILE__)

# Assume that this is a Spark master unless dependent configurations are found
sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]

# Stop the Spark Thrift Server service
service  "spark-thriftserver" do
  action [ :stop ]
  only_if { is_client_only && configNode.has_key?('enable_thriftserver') && configNode['enable_thriftserver'] == 'true' }
end

# Stop the Spark History Server service
service  "spark-historyserver" do
  action [ :stop ]
  only_if { is_client_only && configNode.has_key?('enable_historyserver') && configNode['enable_historyserver'] == 'true' }
end

# Stop the Spark service
service "spark" do
  action [ :stop ]
  only_if { !is_client_only }
end
