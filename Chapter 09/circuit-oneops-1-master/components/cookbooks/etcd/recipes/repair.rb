# Cookbook Name:: etcd
# Attributes:: repair
#
# Author : OneOps
# Apache License, Version 2.0

include_recipe 'etcd::delete'
include_recipe 'etcd::add'