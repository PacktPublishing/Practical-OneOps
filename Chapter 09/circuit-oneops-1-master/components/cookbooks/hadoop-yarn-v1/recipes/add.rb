#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: add
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# get resource manager ips- this definition is in the yarn_helper library
prmNode, srmNode = getRm()

# installs prereq packages
include_recipe "hadoop-yarn-v1::prerequisites"

# installs and configures hadoop
include_recipe "hadoop-yarn-v1::binary_install"

# intra cluster host-based ssh
include_recipe "hadoop-yarn-v1::ssh"

# get the name of resource as defined in the pack code
componentName = node.workorder.rfcCi.ciName
puts "component name is: #{componentName}"

# install init scripts depending on the name of the resource
case componentName
when /^prm/
    if node.ipaddress == prmNode
        puts "i am a primary resource manager and my ip is #{node.ipaddress}, installing prm init script"
        include_recipe "hadoop-yarn-v1::resourcemanager_setup"
        puts "i am a primary name node and my ip is #{node.ipaddress}, installing nn init script"
        include_recipe "hadoop-yarn-v1::namenode_setup"
        puts "i am a secondary name node and my ip is #{node.ipaddress}, installing snn init script"
        include_recipe "hadoop-yarn-v1::secondarynamenode_setup"
        puts "i am a job history server and my ip is #{node.ipaddress}, installing jobhistory init script"
        include_recipe "hadoop-yarn-v1::jobhistory_setup"
        puts "installing gmond"
        include_recipe "hadoop-yarn-v1::gmond"
        puts "prepping ephemeral hdfs dirs"
        include_recipe "hadoop-yarn-v1::prep_dirs"
    end
# when /^srm/
#     puts "i am a secondary resource manager and my ip is #{node.ipaddress}, installing srm init script"
when /^client/
    puts "i am a client and my ip is #{node.ipaddress}"
    include_recipe "hadoop-yarn-v1::hive"
    if toBool(cia["enable_pig"])
        include_recipe "hadoop-yarn-v1::pig"
    end
when /^dn/
    puts "checking Spark support configuration"
    include_recipe "hadoop-yarn-v1::spark"
    puts "i am a data node and my ip is #{node.ipaddress}, installing dn init script"
    include_recipe "hadoop-yarn-v1::datanode_setup"
    puts "i am a node manager and my ip is #{node.ipaddress}, installing nm init script"
    include_recipe "hadoop-yarn-v1::nodemanager_setup"
    # puts "i am a node manager and my ip is #{node.ipaddress}, installing jobhistory init script"
    # include_recipe "hadoop-yarn-v1::jobhistory_setup"
    puts "installing gmond"
    include_recipe "hadoop-yarn-v1::gmond"
else
    # removed exit 1, and replaced with warning so that presto/spark can use without installing init
    # scripts from above, however still have all the hadoop binaries
    puts "WARNING!! component unknown: #{componentName}.  Only base hadoop binaries will be installed"
end
