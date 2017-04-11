name             "Windows-domain"
description      "Windows domain membership Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'domain',
  :description => "Domain Name",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Domain Name',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Specify domain account name with permissions to add/remove computers to domain',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Specify password of the domain account with permissions to add/remove computers to domain',
    :category => '1.Authentication',
    :order => 3
  }
