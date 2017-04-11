#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: secondarynamenode_setup
#
#

# deploys secondarynamenode init script
cookbook_file "/etc/init.d/hadoop-secondarynamenode" do
    source "hadoop-secondarynamenode.init"
    owner 'root'
    group 'root'
    mode '0755'
end

# adds secondarynamenode to chkconfig and starts service
service "hadoop-secondarynamenode" do
    action [:enable, :start]
    supports :restart => true, :reload => true
end
