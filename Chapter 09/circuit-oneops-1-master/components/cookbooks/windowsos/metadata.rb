name             'windowsos'
maintainer       'walmart'
maintainer_email 'kowsalya.palaniappan@walmart.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures windowsos'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog']

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]

grouping 'manifest',
  :access => "global",
  :packages => [ 'manifest' ]
