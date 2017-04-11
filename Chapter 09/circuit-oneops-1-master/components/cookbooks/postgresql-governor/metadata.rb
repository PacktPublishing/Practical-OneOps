name             "Postgresql-governor"
description      "Installs/Configures PostgreSQL Governor"
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
  :default => "9.4",
  :format => {
    :important => true,
    :help => 'Version of PostgreSQL',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['9.4','9.4'], ['9.5','9.5']] },
    :pattern => "[0-9\.]+"
  }
attribute 'governor_download',
 :description => "Governor Package Download URL",
 :required => "required",
 :default => "https://github.com/compose/governor/archive/master.zip",
 :format => {
    :important => true,
    :help => 'The URL of the zip file for PostgreSQL Governor',
    :category => '1.Global',
    :order => 2
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
  :description => "Customimze PostgreSQL config",
  :data_type => "hash",
  :default => '{"max_connections":"100","shared_buffers":"24MB","work_mem":"8MB","ssl":"off","data_directory":"/db"}',
  :format => {
    :important => true,
    :help => 'Customize config. Note: (1) make sure use single quotes for paramter values when needed. (2) parameter values defined here have the highest priority to overwrite',
    :category => '2.Server',
    :order => 2
  }


attribute 'etcd_ttl',
  :description => "Etcd TTL (s)",
  :required => "required",
  :default => "30",
  :format => {
    :help => 'TTL to acquire the leader lock. Think of it as the length of time before automatic failover process is initiated',
    :category => '3.Governor',
    :order => 1,
    :pattern => "[0-9\.]+"
}

attribute 'maximum_lag_on_failover',
  :description => "Maximum Lag on xLog when failover",
  :required => "required",
  :default => "8388608",
  :format => {
    :help => 'The maximum lag on WAL between the Postgres master/leader and slave when the slave could still be considered as the candidate for Postgres master when the failover happens',
    :category => '3.Governor',
    :order => 2,
    :pattern => "[0-9\.]+"
}
recipe "status", "Postgresql Status"
recipe "start", "Start Postgresql"
recipe "stop", "Stop Postgresql"
recipe "restart", "Restart Postgresql"
recipe "repair", "Repair Postgresql"
