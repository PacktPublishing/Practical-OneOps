name             "Database"
description      "Installs/Configures Database"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'dbname',
  :description => "Instance Name",
  :required => "required",
  :default => "db",
  :format => {
    :important => true,
    :help => 'Database instance name',
    :category => '1.Global',
    :order => 1
  }

# TODO add character-set and locale

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "dbuser",
  :format => {
    :important => true,
    :help => 'Username to access this database',
    :category => '1.Global',
    :order => 2
  }

attribute 'password',
  :description => "Password",
  :required => "required",
  :encrypted => true,
  :default => "dbpassword",
  :format => {
    :help => 'Password to access this database',
    :category => '1.Global',
    :order => 3
  }

attribute 'extra',
  :description => "Additional DB statements",
  :data_type => 'text',
  :format => {
    :help => 'Add optional SQL statemements to be executed on configuration changes (Note: use attachments if you need to control when these statesments are executed in the lifecycle events)',
    :category => '1.Global',
    :order => 4
  }

recipe "repair", "Repair"
