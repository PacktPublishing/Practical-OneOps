#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: namenode_setup
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# pull in variables from shared attributes
hadoop_install_dir = cia["hadoop_install_dir"]
hadoop_latest_dir = "#{hadoop_install_dir}/hadoop"
hadoop_user = cia["hadoop_user"]
swift_tmp_dir = cia["swift_tmp_dir"]

# deploy namenode init script
cookbook_file "/etc/init.d/hadoop-namenode" do
    source "hadoop-namenode.init"
    owner 'root'
    group 'root'
    mode '0755'
end

# namenode format if it hasn't been done yet
bash "namenode format" do
    user "root"
    code <<-EOF
        /etc/init.d/hadoop-namenode format
    EOF
    not_if "/bin/ls -ld #{swift_tmp_dir}/dfs"
end

# add namenode to chkconfig and start service
service "hadoop-namenode" do
    action [:enable, :start]
    supports :restart => true, :reload => true
end
