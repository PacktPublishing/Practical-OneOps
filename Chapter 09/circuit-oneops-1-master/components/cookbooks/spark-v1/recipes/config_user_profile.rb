# config_user_profile - Set up Spark user profile
#
# This recipe sets up some convenient aliases for the Spark user

require File.expand_path("../spark_helper.rb", __FILE__)

# Determine the Spark version
sparkInfo = get_spark_info()
configNode = sparkInfo[:config_node]

# Spark directories
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

template "/home/spark/.bash_profile" do
  source "bash_profile.erb"
  owner "spark"
  group "spark"
  action :create
  variables ({
    :spark_dir => spark_dir
  })
end
