#
# Cookbook Name:: f5-bigip
# Recipe:: f5_delete_pool
#
# Copyright 2013 Walmart Labs


#include_recipe 'f5-bigip::provision_configsync'
require_relative "../libraries/resource_config_sync"

lbs = [] + node.loadbalancers + node.dcloadbalancers

lbs.each do |lb|
  lbparts = lb['name'].split("-")
  lbparts.pop
  base_pool_name =  "str-" + lbparts.join("-") + "-pool"
  f5_ltm_pool "#{base_pool_name}" do
    pool_name "#{base_pool_name}"
    f5 "#{node.f5_host}"
    action :delete
    notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
  end

end
