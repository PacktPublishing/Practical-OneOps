#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: resourcemanager_setup
#
#

# deploy resource manager init script
cookbook_file "/etc/init.d/hadoop-resourcemanager" do
    source "hadoop-resourcemanager.init"
    owner 'root'
    group 'root'
    mode '0755'
end

# add resourcemanager to chkconfig and start service
service "hadoop-resourcemanager" do
    action [:enable, :start]
    supports :restart => true, :reload => true
end
