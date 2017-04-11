name             'Hadoop-yarn-v1'
maintainer       '@WalmartLabs'
maintainer_email 'dmoon@walmartlabs.com'
description      'Hadoop YARN (v1 build)'
long_description 'Hadoop YARN (v1 build)'
version          '1.0.0'

grouping 'default',
    :access => "global",
    :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


recipe 'resourcemanager_restart', 'Restart Resource Manager'
recipe 'namenode_restart', 'Restart Name Node'
recipe 'datanode_restart', 'Restart Data Node'
recipe 'nodemanager_restart', 'Restart Node Manager'
recipe 'thrift_restart', 'Restart Thrift Service'
recipe 'hiveserver2_restart', 'Restart Hiverserver2 Service'
