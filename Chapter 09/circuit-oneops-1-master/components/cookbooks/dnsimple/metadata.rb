name             "Dnsimple"
description      "DNSimple Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'email',
  :description => "Email",
  :required => "required",
  :default => "",
  :format => { 
    :help => 'Email',
    :category => '1.Credentials',
    :order => 1
  }
  
attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Password', 
    :category => '1.Credentials',
    :order => 2
  }
  
attribute 'zone',
  :description => "Zone",
  :default => "",
  :format => {
    :help => 'Specify the zone name where to insert DNS records', 
    :category => '2.DNS',
    :order => 1
  }
    
