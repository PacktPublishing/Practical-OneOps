#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: nodemanager_setup
#
#

# deploy nodemanager init script
cookbook_file "/etc/init.d/hadoop-nodemanager" do
    source "hadoop-nodemanager.init"
    owner 'root'
    group 'root'
    mode '0755'
end

# add nodemanager to chkconfig and start service
service "hadoop-nodemanager" do
    action [:enable, :start]
    supports :restart => true, :reload => true
end
