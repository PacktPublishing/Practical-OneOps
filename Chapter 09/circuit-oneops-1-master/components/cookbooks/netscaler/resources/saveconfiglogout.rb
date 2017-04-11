#
# Cookbook Name:: netscaler
# Resource:: saveconfiglogout
#

require 'resolv'

actions :default
default_action :default

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true

attribute :connection, 
  :kind_of => Object,
  :required => true 
