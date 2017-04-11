#
# Cookbook Name:: netscaler
# Resource:: server
#

require 'resolv'

actions :create, :delete
default_action :create

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true 
  
attribute :ipaddress, 
  :kind_of => String,
  :required => true, 
  :regex => [Resolv::IPv4::Regex, Resolv::IPv6::Regex]

attribute :connection, 
  :kind_of => Object,
  :required => true 
