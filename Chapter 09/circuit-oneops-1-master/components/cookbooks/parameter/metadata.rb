name             "Parameter"
description      "Input/Output Parameters"
version          "0.1"
maintainer       "Oneops, Inc."
maintainer_email "dev@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base' ]

grouping 'encrypted',
  :access => "global",
  :packages => [ 'encrypted' ]
    
attribute 'value',
  :description => "Value",
  :grouping => 'default',
  :default => "",
  :format => {
    :help => 'Enter the parameter value',
    :category => '1.Properties',
    :order => 1
  }
  
attribute 'value',
  :description => "Value",
  :grouping => 'encrypted',
  :default => "",
  :encrypted => true,
  :format => {
    :help => 'Enter the parameter value',
    :category => '1.Properties',
    :order => 1
  }