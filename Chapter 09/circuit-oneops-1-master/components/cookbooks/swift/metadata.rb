name             'Swift'
maintainer       '@WalmartLabs'
maintainer_email 'umullangi@walmartlabs.com'
license          'All rights reserved'
description      'Installs/Configures swift-client'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
grouping 'default',
  :access => 'global',
  :packages => %w(base service.filestore mgmt.cloud.service cloud.service cloud.zone.service),
  :namespace => true

attribute 'endpoint',
          :description => "Auth Endpoint",
          :required => "required",
          :default => "",
          :format => {
              :help => 'Auth Endpoint URL',
              :category => '1.Authentication',
              :order => 1
          }

attribute 'tenant',
          :description => "Tenant",
          :required => "required",
          :default => "",
          :format => {
              :help => 'Tenant Name',
              :category => '1.Authentication',
              :order => 2
          }

attribute 'regionname',
          :description => "Region Name",
          :encrypted => false,
          :required => "required",
          :default => "",
          :format => {
              :help => 'Region Name Attribute',
              :category => '1.Authentication',
              :order => 3
          }


attribute 'authstrategy',
          :description => "Auth Strategy",
          :encrypted => false,
          :required => "optional",
          :default => "keystone",
          :format => {
              :help => 'Auth Strategy',
              :category => '1.Authentication',
              :order => 4
          }

attribute 'username',
          :description => "Username",
          :format => {
              :help => 'Username',
              :category => '1.Authentication',
              :order => 5
          }

attribute 'password',
          :description => "Password",
          :encrypted => true,
          :format => {
              :help => 'Password',
              :category => '1.Authentication',
              :order => 6
          }

