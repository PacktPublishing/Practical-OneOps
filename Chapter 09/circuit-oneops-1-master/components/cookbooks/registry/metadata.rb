name             "Registry"
description      "Docker Compatible Container Registry"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.compute', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'location',
  :description => "Server Location",
  :default => "",
  :format => {
    :help => 'Example: registry.local:5000',
    :important => true,
    :category => '1.Server',
    :order => 1
  }

attribute 'username',
  :description => "Username",
  :format => {
    :help => 'Username',
    :category => '2.Authentication',
    :order => 1
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :format => {
    :help => 'Password',
    :category => '2.Authentication',
    :order => 2
  }

attribute 'email',
  :description => "Email",
  :format => {
    :help => 'Email',
    :category => '2.Authentication',
    :order => 3
  }
