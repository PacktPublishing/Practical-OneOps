name             'Spark-cluster-v1'
maintainer       '@WalmartLabs'
maintainer_email 'paas@email.wal-mart.com'
license          'All rights reserved'
description      'Spark cluster component (V1 build)'
long_description 'Version 1'
version '1.0.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]

attribute 'dns_record',
    :description => "DNS Record value used by FQDN",
    :grouping => 'bom',
    :format => {
        :important => true,
        :help => 'DNS Record value used by FQDN',
        :category => '1.Operations',
        :order => 1
    }

# Actions
recipe "restart_cluster", "Restart Spark Cluster"
