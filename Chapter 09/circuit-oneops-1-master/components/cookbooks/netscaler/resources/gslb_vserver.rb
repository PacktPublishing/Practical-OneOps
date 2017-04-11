#
# Cookbook Name:: netscaler
# Resource:: gslb_vserver
#

require 'resolv'

actions :create, :delete
default_action :create

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true 

attribute :servicetype, 
  :kind_of => String,
  :required => true

attribute :dnsrecordtype,
  :kind_of => String,
  :required => true  

attribute :domain,
  :kind_of => String,
  :required => true  
 
attribute :lbmethod,
  :kind_of => String,
  :required => true  

attribute :connection, 
  :kind_of => Object,
  :required => true 
