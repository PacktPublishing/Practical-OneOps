# Cookbook Name:: activemq
# Recipe:: externalstorage
#


ci = node.workorder.rfcCi.ciAttributes

runasuser ="#{node['activemq']['runasuser']}"
mount_point="#{node['activemq']['datapath']}"

Chef::Log.info("Mount Point #{mount_point}")

rfc_action = "#{node.workorder.rfcCi.rfcAction}"

depnd = node.workorder.payLoad[:DependsOn]
depnd.each do | vol_info |
  if vol_info[:ciName] =~ /^volume-externalstorage/
    mount_point = vol_info[:ciAttributes][:mount_point]
    break
   end
end

directory "#{mount_point}" do
    mode 00777
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

node.set[:activemq][:datapath]="#{mount_point}"

Chef::Log.info("datapath #{node['activemq']['datapath']}")
