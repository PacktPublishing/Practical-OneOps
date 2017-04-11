name             "Powerdns"
description      "Power DNS"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]
  
attribute 'soa_name',
  :description => "SOA Name",
  :default => '',
  :format => { 
    :category => '1.Server', 
    :order => 1, 
    :help => 'Default SOA name'
  }
  
attribute 'ttl',
  :description => "Default TTL",
  :default => '3600',
  :required => 'required',
  :format => { 
    :category => '1.Server', 
    :order => 2,
    :help => 'Default TTL in seconds'
  }
 
attribute 'threads',
  :description => "Distributor Threads",
  :default => '5',
  :format => { 
    :category => '1.Server', 
    :order => 3, 
    :help => 'Distributor threads'
  }
    
attribute 'allow_axfr_ips',
  :description => "Allow zone transfers IP List",
  :default => '[ "127.0.0.1" ]',
  :data_type => 'array',
  :format => { 
    :category => '2.Security', 
    :order => 1, 
    :help => 'Provide a list of source IP addresses that are allowed to perform zone transfers'
  }

attribute 'allow_recursion',
  :description => "Recursion Subnets",
  :data_type => 'array',
  :default => '[ "127.0.0.1" ]',
  :format => { 
    :category => '3.Recursion', 
    :order => 1, 
    :help => 'List of subnets that are allowed to recurse', 
  }

attribute 'backend',
  :description => "Backend",
  :default => 'gmysql',
  :required => 'required',
  :format => { 
    :category => '4.Database', 
    :order => 1, 
    :help => 'The FQDN or IP address of the database backend', 
    :form => { 'field' => 'select', 'options_for_select' => [ ['Generic SQLite','gsqlite3'],
                                                              ['Generic MySQL','gmysql'],
                                                              ['Generic PostgreSQL','gpgpsql'] ]
    }
  }
    
attribute 'dbserver',
  :description => "Server Name",
  :default => '127.0.0.1',
  :required => 'required',
  :format => { 
    :category => '4.Database', 
    :order => 2, 
    :help => 'The FQDN or IP address of the database backend', 
  }
  
attribute 'dbname',
  :description => "Database Name",
  :default => 'powerdns',
  :required => 'required',
  :format => { 
    :category => '4.Database', 
    :order => 3, 
    :help => 'The name of the database instance', 
  }
  
attribute 'dbuser',
  :description => "Username",
  :default => 'powerdns',
  :required => 'required',
  :format => { 
    :category => '4.Database', 
    :order => 4, 
    :help => 'The FQDN or IP address of the database backend', 
  }
  
attribute 'dbpassword',
  :description => "Password",
  :default => 'powerdns',
  :required => 'required',
  :encrypted => true,
  :format => { 
    :category => '4.Database', 
    :order => 5, 
    :help => 'The FQDN or IP address of the database backend', 
  }
  
recipe "repair", "Repair"