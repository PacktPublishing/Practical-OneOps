name             "Mirror"
description      "Installs/Configures Software Download Mirrors"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom', 'service.mirror', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'mirrors',
  :description => "Mirrors",
  :data_type => 'hash',  
  :default => '{"apache":"http://archive.apache.org/dist"}',
  :format => {
    :category => '1.Locations',
    :help => 'Locations of base mirror URLs',
    :order => 1
  } 
    
recipe "status", "Mirror Status"
recipe "start", "Start Mirror Replication"
recipe "stop", "Stop Mirror Replication"


