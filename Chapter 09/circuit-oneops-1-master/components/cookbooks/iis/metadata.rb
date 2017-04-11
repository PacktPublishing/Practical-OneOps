name             'iis'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'All rights reserved'
description      'Installs/Configures iis'
version          '0.1.0'

grouping 'default',
  :access   => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]
