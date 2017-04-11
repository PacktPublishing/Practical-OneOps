#
# Cookbook Name:: netscaler
# Resource:: gslb_service
#

require 'resolv'

actions :create, :delete
default_action :create

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true 

attribute :state, 
  :kind_of => String,
  :required => true

attribute :gslb_vserver, 
  :kind_of => String,
  :required => true

attribute :sitename, 
  :kind_of => String,
  :required => true
  
attribute :servername, 
  :kind_of => String,
  :required => true

attribute :serverip, 
  :kind_of => String,
  :required => true

attribute :servicetype, 
  :kind_of => String,
  :required => true
 
attribute :port,
  :kind_of => Integer,
  :required => true  

attribute :iport,
  :kind_of => Integer,
  :required => true

attribute :connection, 
  :kind_of => Object,
  :required => true 
