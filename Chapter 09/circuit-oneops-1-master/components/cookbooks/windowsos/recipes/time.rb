
#
# Cookbook Name:: windowsos
# Recipe:: time
#
# Copyright 2016, Walmart
#
#

Chef::Log.info("In Windows Time recipe")
services = node[:workorder][:services]
cloud_name = node[:workorder][:cloud][:ciName]
ntp_service = services["ntp"][cloud_name]
ntpservers = JSON.parse(ntp_service[:ciAttributes][:servers])

windowsos_time "timezone_settings" do
     timezone_name node.workorder.rfcCi.ciAttributes.timezone
     action :set_time_zone
  end

if node[:workorder][:services].has_key?(:ntp)
  windowsos_time "ntpserver_settings" do
     ntpserver_names ntpservers
     action :set_ntpservers
  end
end
