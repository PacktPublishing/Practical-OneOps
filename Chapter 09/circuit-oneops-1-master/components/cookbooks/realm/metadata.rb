name             "Realm"
description      "Realm for Containers"
version          "0.1"
maintainer       "OneOps, Inc."
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'account', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]


  attribute 'labels',
    :description => "Labels",
    :data_type => "hash",
    :default => "{}",
    :format => {
      :help => 'Enter key/value entries to identify this realm',
      :category => '1.Identity',
      :order => 1
    }


recipe "repair", "Repair"
