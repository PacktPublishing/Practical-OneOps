name             "Library"
description      "Software library items"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'packages',
  :description => "Package List",
  :data_type => "array",
  :required => "required",
  :default => '[]',
  :format => {
    :important => true,
    :category => '1.Global',
    :help => 'List of OS package names (Note: use OS type filters to ensure compatibility)',
    :order => 1
  }

recipe "repair", "Repair"
