#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: spark
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get attributes
cia = getCia()

spark_dist = ""

cloud_local_vars = node.workorder.payLoad.OO_LOCAL_VARS
cloud_local_vars.each do |var|
  if var[:ciName] == "SPARK_DIST"
    spark_dist = "#{var[:ciAttributes][:value]}"
  end
end

hadoop_install_dir = cia["hadoop_install_dir"]
spark_dest_dir = "#{hadoop_install_dir}/hadoop/share/hadoop/yarn"

if spark_dist == ""
  # Remove the Spark files
  bash "install_spark" do
    user "root"
    code <<-EOF
      rm -f "#{spark_dest_dir}/spark-*"
    EOF
  end
else
  # Spark install
  bash "install_spark" do
      user "root"
      code <<-EOF
          /usr/bin/curl "#{spark_dist}" |
          /bin/tar xvz -C /tmp --strip-components=1 **/yarn/*
          chown yarn:yarn /tmp/yarn/*
          mv /tmp/yarn/* "#{spark_dest_dir}"
      EOF
      not_if "/bin/ls #{spark_dest_dir}/spark-*"
  end
end
