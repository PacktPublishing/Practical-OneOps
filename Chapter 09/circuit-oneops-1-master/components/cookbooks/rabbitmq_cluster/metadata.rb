name             "Rabbitmq_cluster"
description      "Setup/Configure Rabbitmq Cluster"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Copyright OneOps, All rights reserved."

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

recipe "app_status", "app status"
recipe "app_stop", "app stop"
recipe "app_start", "app start"
recipe "cluster_status", "cluster status"
