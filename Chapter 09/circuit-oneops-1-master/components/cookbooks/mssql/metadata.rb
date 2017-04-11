name             'Mssql'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/configures Microsoft SQL Server'
version          '0.1.0'

depends 'os'

grouping 'default',
  :access   => 'global',
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => 'MS SQL Server version and edition',
  :default     => 'mssql_2014_enterprise',
  :format      => {
    :help      => 'Select version and edition of MS SQL Server to be installed',
    :category  => '1.Global',
    :order     => 1,
    :form => { 'field' => 'select', 'options_for_select' => [ ['2014 Enterprise', 'mssql_2014_enterprise'], ['2016 Enterprise', 'mssql_2016_enterprise'] ] }
	}

attribute 'password',
  :description => 'sa Password',
  :required => 'required',
  :encrypted => true,
  :default => 'mssql',
  :format => {
    :help => 'sa password used for administration of the MS SQL Server',
    :category => '1.Global',
    :order => 2
  }

attribute 'tempdb_data',
  :description => 'TempDB data directory',
  :format => {
    :help => 'Default directory for tempdb data files',
    :category => '2.Directories',
    :order => 1
  }

attribute 'tempdb_log',
  :description => 'TempDB log directory',
  :format => {
    :help => 'Default directory for tempdb log file',
    :category => '2.Directories',
    :order => 2
  }
  
attribute 'userdb_data',
  :description => 'User db data directory',
  :format => {
    :help => 'Default directory for user databases',
    :category => '2.Directories',
    :order => 3
  }

attribute 'userdb_log',
  :description => 'User db log directory',
  :format => {
    :help => 'Default directory for user database logs',
    :category => '2.Directories',
    :order => 4
  }  