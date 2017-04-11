#
# Cookbook Name:: f5-bigip
# Resource:: getsetiplb
#
#require_relative "../providers/getsetlbip"

actions :create
default_action :create

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true 

attribute :ipv46, 
  :kind_of => String

attribute :f5_ip, 
  :kind_of => String
