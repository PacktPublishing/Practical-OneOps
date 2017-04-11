#
# Cookbook Name:: keypair
# Recipe:: update
#
# Copyright 2013, OneOps
#
# All rights reserved - Do Not Redistribute

include_recipe "keypair::delete"
include_recipe "keypair::add"
