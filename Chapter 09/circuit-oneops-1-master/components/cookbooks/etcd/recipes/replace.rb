# Cookbook Name:: etcd
# Attributes:: replace
#
# Author : OneOps
# Apache License, Version 2.0

extend Etcd::Util
Chef::Resource::RubyBlock.send(:include, Etcd::Util)

if depend_on_hostname_ptr?
  include_recipe 'etcd::delete'
  include_recipe 'etcd::register_new_node'  
end

include_recipe 'etcd::add'
