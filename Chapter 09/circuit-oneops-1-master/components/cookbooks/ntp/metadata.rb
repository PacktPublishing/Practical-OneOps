name             "Ntp"
description      "Network Time Protocol"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.ntp', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'servers',
  :description => "Servers",
  :required => "required",
  :data_type => 'array',
  :default => '[]',
  :format => {
    :help => 'List of servers running ntpd',
    :category => '1.General',
    :order => 1
  }
