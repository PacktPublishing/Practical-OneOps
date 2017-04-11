#
# Cookbook Name:: java
# Recipe:: delete
#
# Copyright 2015, @WalmartLabs.
#

# Cleanup the java profile file.

#file '/etc/profile.d/java.sh' do
#  owner 'root'
#  group 'root'
#  action :delete
#end

filePath = node.workorder.rfcCi.ciAttributes.folderpath
file "#{filePath}" do
  action :delete
end
