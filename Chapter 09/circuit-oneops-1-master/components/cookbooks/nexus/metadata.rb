name             "Nexus"
description      "Nexus cloud service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"
depends          "shared"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

grouping 'service',
  :access => "global",
  :packages => [ 'service.maven', 'mgmt.cloud.service', 'cloud.service'  ],
  :namespace => true

attribute 'url',
  :grouping => 'service',
  :description => "Repository URL",
  :required => "required",
  :default => '',
  :format => { 
    :help => 'Nexus repository URL',
    :category => '1.Repository',
    :order => 1
  }

attribute 'repository',
  :grouping => 'service',
  :description => "Default Repository",
  :required => "required",
  :default => '',
  :format => { 
    :help => 'Default repository if not specified in configuration',
    :category => '1.Repository',
    :order => 2
  }
  
attribute 'username',
  :grouping => 'service',
  :description => "Username",
  :format => {
    :help => 'Username to authenticate against the Nexus repository',
    :category => '2.Authentication',
    :order => 1
  }

attribute 'password',
  :grouping => 'service',
  :description => "Password",
  :encrypted => true,
  :format => {
    :help => 'Password to authenticate against the Nexus repository',
    :category => '2.Authentication',
    :order => 2
  }
