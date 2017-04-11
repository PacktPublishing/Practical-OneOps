#
# Cookbook Name:: f5-bigip
# Recipe:: f5_delete_monitor
#
# Copyright 2013 Walmart Labs


include_recipe "f5-bigip::get_monitor_name"

node.monitors.each do |mon|
  mon_name = mon[:monitor_name]
  f5_ltm_monitor "#{mon_name}" do
    f5 "#{node.f5_host}"
    monitor_name  mon_name
    action :delete
    notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
  end
end
