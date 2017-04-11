#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: prep_dirs
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# pull in variables from shared attributes
hadoop_install_dir = cia["hadoop_install_dir"]
$hadoop_latest_dir = "#{hadoop_install_dir}/hadoop"
$hadoop_user = cia["hadoop_user"]

# recursively create hdfs directory
def createHdfsDir(dirToCreate, permToSet, recursivePermStartDir)
    hadoop_latest_dir = $hadoop_latest_dir
    hadoop_user = $hadoop_user
    bash "creating #{dirToCreate} dir" do
        user "#{hadoop_user}"
        code <<-EOF
            #{hadoop_latest_dir}/bin/hdfs dfs -mkdir -p #{dirToCreate}
            #{hadoop_latest_dir}/bin/hdfs dfs -chmod -R #{permToSet} #{recursivePermStartDir}
        EOF
        not_if "#{hadoop_latest_dir}/bin/hdfs dfs -ls #{dirToCreate}"
    end
end

##############################################################
# below are the directories to be created using above method

# create tmp dir
createHdfsDir("/tmp/hive", "1777", "/tmp")

# make hadoop history dir
createHdfsDir("/tmp/hadoop-yarn/staging/history/done_intermediate", "1777", "/tmp")

# make warehouse dir
createHdfsDir("/user/hive/warehouse", "1777", "/user")

# make job history log dir
createHdfsDir("/var/log/hadoop-yarn", "1777", "/var/log/hadoop-yarn")
