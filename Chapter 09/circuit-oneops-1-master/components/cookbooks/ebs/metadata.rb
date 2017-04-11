name             "Ebs"
description      "Amazon Web Services - EC2 Elastic Block Storage"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'key',
  :description => "Access Key",
  :required => "required",
  :default => "",
  :format => { 
    :help => 'Access key from the AWS security credentials page',
    :category => '1.Credentials',
    :order => 1
  }
  
attribute 'secret',
  :description => "Secret Key",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Secret key from the AWS security credentials page', 
    :category => '1.Credentials',
    :order => 2
  }

attribute 'region',
  :description => "Region",
  :default => "",
  :format => {
    :help => 'Region Name',
    :category => '2.Placement',
    :order => 1
  }

    
