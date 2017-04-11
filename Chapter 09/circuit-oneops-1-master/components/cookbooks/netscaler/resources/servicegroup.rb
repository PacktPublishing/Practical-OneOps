#
# Cookbook Name:: netscaler
# Resource:: servicegroup
#
actions :create, :delete
default_action :create

attribute :name, 
  :name_attribute => true, 
  :kind_of => String,
  :required => true 
  
attribute :port, 
  :kind_of => String,
  :required => true
                
attribute :protocol, 
  :kind_of => String,
  :required => true

              
attribute :connection, 
  :kind_of => Object,
  :required => true 

