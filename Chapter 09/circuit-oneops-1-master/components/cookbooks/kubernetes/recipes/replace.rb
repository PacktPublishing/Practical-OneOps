# Cookbook Name:: kubernetes
# Attributes:: replace
#
# Author : OneOps
# Apache License, Version 2.0

include_recipe 'kubernetes::delete'
include_recipe 'kubernetes::add'
