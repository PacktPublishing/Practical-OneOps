# Delete - Delete the Spark components
#
# This recipe removes all components used for Spark.

Chef::Log.info("Running #{node['app_name']}::delete")

configName = node['app_name']
configNode = node[configName]

dependentCiClass = "bom.oneops.1." + configName.slice(0,1).capitalize + configName.slice(1..-1)
spark_configs=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] != dependentCiClass }
if (!spark_configs.nil? && !spark_configs[0].nil?)
  Chef::Log.info("Found dependent configuration")
  configNode = spark_configs[0][:ciAttributes]
end

# The parent directory for all Spark files
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

# Find the target of the link
link_target = `readlink -f #{spark_dir}`

spark_cache_path = Chef::Config[:file_cache_path] + "/spark"

# Make sure Spark is stopped before removing components
include_recipe "#{node['app_name']}::spark_stop"

directory spark_cache_path do
  owner 'root'
  group 'root'
  mode  '0755'
end

# Delete the service startup script.
file "/etc/init.d/spark" do
  action :delete
end

# Delete the user Spark tools
for sparkTool in ['spark-submit', 'spark-sql', 'spark-shell', 'sparkR', 'run-example', 'spark-class', 'pyspark'] do
  file "/usr/bin/#{sparkTool}" do
    action :delete
  end
end

# Delete the beeline tool
file "/usr/bin/beeline" do
  action :delete
end

# Delete the symlink to the archive
link spark_dir do
  to     link_target
  action :delete
end

# Delete the spark archive directory
directory link_target do
  action    :delete
  recursive true
end

# With the Spark directory being /opt, don't remove it recursively
# since other components may be present in there
## Delete the spark directory
#directory "#{spark_base}" do
#  action    :delete
#  recursive true
#end

# Clean up all locally generated files

directory spark_cache_path do
  action    :delete
  recursive true
end
