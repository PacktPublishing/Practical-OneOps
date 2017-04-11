name             'Panos'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures Palo Alto Firewall devices'
version          '0.1.0'

grouping 'default',
 :access => "global",
 :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
 :namespace => true

attribute 'endpoint',
 :description => "API Endpoint",
 :required => "required",
 :default => "",
 :format => {
   :help => 'API Endpoint URL',
   :category => '1.Authentication',
   :order => 1
 }

attribute 'username',
 :description => "Username",
 :required => "required",
 :default => "",
 :format => {
   :help => 'API Username',
   :category => '1.Authentication',
   :order => 2
 }

attribute 'password',
 :description => "Password",
 :encrypted => true,
 :required => "required",
 :default => "",
 :format => {
   :help => 'API Password',
   :category => '1.Authentication',
   :order => 3
 }
