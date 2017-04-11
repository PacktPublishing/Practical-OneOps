name             "Postgresql"
description      "Installs/Configures PostgreSQL"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => "9.2",
  :format => {
    :important => true,
    :help => 'Version of PostgreSQL',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['9.2','9.2'],['9.6','9.6']] },
    :pattern => "[0-9\.]+"
  }


attribute 'port',
  :description => "Listen port",
  :required => "required",
  :default => "5432",
  :format => {
    :help => 'Port that PostgreSQL server will listen on for connections',
    :category => '2.Server',
    :order => 1,
    :pattern => "[0-9\.]+"
  }

attribute 'postgresql_conf',
  :description => "Custom postgresql.conf",
  :data_type => "hash",
  :default => "{}",
  :format => {
    :important => true,
    :help => 'Custom entries for postgresql.conf (Note: make sure you use single quotes for paramter values that need them)',
    :category => '2.Server',
    :order => 2
  }

attribute 'strict_replicators',
  :description => "Strict Replicators",
  :default => 'false',
  :format => {
    :form => { 'field' => 'checkbox' },
    :help => 'Strict replicators mode allows only the secondary clouds\' IPs',
    :category => '2.Server',
    :order => 3
  }

recipe "status", "Postgresql Status"
recipe "start", "Start Postgresql"
recipe "stop", "Stop Postgresql"
recipe "restart", "Restart Postgresql"
recipe "repair", "Repair Postgresql"
