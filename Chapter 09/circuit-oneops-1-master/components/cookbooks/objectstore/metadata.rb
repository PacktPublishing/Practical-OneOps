name             'Objectstore'
maintainer       '@walmartlabs'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures object-store'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
depends 	'swift'
grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

# Authentication
attribute 'username',
          :description => "Username",
          :required => "required",
          :default => "changeme",
          :format => {
              :help => 'API Username',
              :category => '1.Authentication',
              :order => 1
          }

attribute 'password',
          :description => "Password",
          :encrypted => true,
          :required => "required",
          :default => "changeme",
          :format => {
              :help => 'API Password',
              :category => '1.Authentication',
              :order => 2
          }
# bucket
attribute 'bucketname',
          :description => "Bucket Name",
          :default => "",
          :format => {
              :help => 'Name of the bucket to be created on object-store',
              :category => '2.Bucket',
              :order => 1
          }
