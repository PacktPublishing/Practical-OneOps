#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: datanode_setup
#
#

# install datanode init script
cookbook_file "/etc/init.d/hadoop-datanode" do
    source "hadoop-datanode.init"
    owner 'root'
    group 'root'
    mode '0755'
end

# add datanode service to chkconfig and start service
service "hadoop-datanode" do
    action [:enable, :start]
    supports :restart => true, :reload => true
end
