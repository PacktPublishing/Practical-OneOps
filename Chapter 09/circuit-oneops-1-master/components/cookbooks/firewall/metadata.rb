name             'Firewall'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures firewall'
version          '0.1.0'
depends          'panos'

grouping 'default',
 :access => "global",
 :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
 :namespace => true

attribute 'devicegroups',
          :description => "Device Groups",
          :required => false,
          :data_type => "array",
          :default => '[]',
          :format => {
              :help => 'Device Groups - Required if using Panos firewall cloud service.',
              :category => '1.Panos Configuration',
              :order => 1
          }
