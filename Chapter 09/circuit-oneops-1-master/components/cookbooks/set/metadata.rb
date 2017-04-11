name             "Set"
description      "Container Set"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]


attribute 'replicas',
  :description => "Replicas",
  :required => "required",
  :default => '3',
  :format => {
    :help => 'Number of replicas',
    :category => '1.Scale',
    :order => 1
  }

attribute 'parallelism',
  :description => "Parallelism",
  :required => "required",
  :default => '1',
  :format => {
    :help => 'Maximum number of replicas to be updated in parallel',
    :category => '2.Update Strategy',
    :order => 1
  }

recipe "repair", "Repair"
