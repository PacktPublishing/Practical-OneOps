name             "Ring"
description      "Ring Management"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

depends 'couchbase'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]

attribute 'description',
  :description => "Description",
  :default => "",
  :format => {
    :help => "Description",
    :category => '1.Global',
    :order => 1
  }

attribute 'extra',
  :description => "Custom Ring Configuration",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter additional configurational directives to be included when creating the ring (depends on the ring type)',
    :category => '1.Global',
    :order => 2
  }

attribute 'dns_record',
  :description => "DNS Record value used by FQDN",
  :grouping => 'bom',
  :format => {
    :important => true,
    :help => 'DNS Record value used by FQDN',
    :category => '2.Operations',
    :order => 1
  }

recipe "repair", "Repair Ring"
