name             "Mysql"
description      "Installs/Configures MySQL"
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
  :default => "5.5",
  :format => {
    :help => 'Version of MySQL',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [ ['5.5','5.5'], ['5.6','5.6'], ['5.7','5.7'] ] },
    :pattern => "[0-9\.]+"
  }

attribute 'password',
  :description => "System Password",
  :required => "required",
  :encrypted => true,
  :default => "mysql",
  :format => {
    :help => 'System password used for administration of the MySQL database',
    :category => '1.Global',
    :order => 2
  }
  
attribute 'port',
  :description => "Listen port",
  :required => "required",
  :default => "3306",
  :format => {
    :help => 'Port that MySQL server will listen on for connections',
    :category => '2.Server',
    :order => 1,
    :pattern => "[0-9\.]+"
  }

attribute 'datadir',
  :description => "Data Directory",
  :default => "",
  :format => {
    :help => 'Directory path where the database files will be stored',
    :category => '2.Server',
    :order => 2
  }

#recipe "status", "Mysql Status"
recipe "start", "Start Mysql"
recipe "stop", "Stop Mysql"
recipe "restart", "Restart Mysql"
#recipe "repair", "Repair Mysql"

