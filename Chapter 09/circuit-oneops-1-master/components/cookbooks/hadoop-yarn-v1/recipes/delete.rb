#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: delete
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get attributes
cia = getCia()

# killing all java processes
ruby_block "killing all java processes" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("killall java; true ",
            :live_stream => Chef::Log::logger)
    end
end

# set up variables for hadoop install location
hadoop_install_dir = cia["hadoop_install_dir"]
hadoop_tarball = cia["yarn_tarball"]
hadoop_version = hadoop_tarball.split("/")[-1].split("-")[-1].split(".tar")[0]
hadoop_latest_dir = "#{hadoop_install_dir}/hadoop"

# delete symbolic link to hadoop latest
link "#{hadoop_latest_dir}" do
    to "#{hadoop_install_dir}/hadoop-#{hadoop_version}"
    action :delete
end

# delete hadoop dir
directory "#{hadoop_install_dir}/hadoop-#{hadoop_version}" do
    action :delete
    recursive true
end

# delete hadoop profile.d script
puts "deleting hadoop profile script"
file "/etc/profile.d/hadoop.sh" do
    action :delete
end

# delete java profile.d script
puts "deleting hadoop profile script"
file "/etc/profile.d/java.sh" do
    action :delete
end

# delete init scripts
componentName = node.workorder.rfcCi.ciName
puts "component name is: #{componentName}"
case componentName
when /^prm/
    puts "deleting init script for primary resource manager"
    file "/etc/init.d/hadoop-resourcemanager" do
        action :delete
    end
    puts "deleting init script for name node"
    file "/etc/init.d/hadoop-namenode" do
        action :delete
    end
    puts "deleting init script for secondary name node"
    file "/etc/init.d/hadoop-secondarynamenode" do
        action :delete
    end
# when /^srm/
#     puts "i am a secondary resource manager and my ip is #{node.ipaddress}, installing srm init script"
# when /^client/
    # hive_user = cia["hive_user"]
    # hive_install_dir = cia["hive_install_dir"]
    # hive_mirror = cia["hive_mirror"]
    # hive_version = cia["hive_version"]
    # hive_path = "#{hive_install_dir}/apache-hive-#{hive_version}-bin"
    # puts "deleting hive home dir"
    # directory "/home/#{hive_user}" do
    #     action :delete
    #     recursive true
    # end
    # puts "deleting log dir"
    # directory "/work/logs" do
    #     action :delete
    #     recursive true
    # end
    # puts "deleting hive install dir"
    # directory "#{hive_install_dir}" do
    #     action :delete
    #     recursive true
    # end
    # puts "deleting hive profile script"
    # file "/etc/profile.d/hive.sh" do
    #     action :delete
    # end
when /^dn/
    puts "deleting init script for data node"
    file "/etc/init.d/hadoop-datanode" do
        action :delete
    end
    puts "deleting init script for node manager"
    file "/etc/init.d/hadoop-nodemanager" do
        action :delete
    end
else
    puts "component unknown: #{componentName}"
    exit 1
end
