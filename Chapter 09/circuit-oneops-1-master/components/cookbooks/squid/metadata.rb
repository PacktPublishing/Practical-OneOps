name             "Squid"
description      "Installs/Configures Squid"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'install_type',
  :description => "Version",
  :required => "required",
  :default => "3.3.8",
  :format => {
    :category => '1.Source',
    :help => 'Provide the Squid version that available in the OS repository. Ex: 3.3.8',
    :order => 1,
  }

 attribute 'acl_values',
  :description => "ACL",
  :required => "required",
  :data_type => 'array',
  :default => '[]',
  :format => {
    :help => 'ACL format <acl_name> <type> <data>. Ex: localhost src 0.0.0.0/0',
    :category => '2.ACL',
    :order => 1
  }

  attribute 'http_access_allow',
  :description => "Http Access Allow",
  :data_type => 'array',
  :default => '[]',
  :format => {
    :help => 'Http Access Allow format <acl_name>. Ex: localhost',
    :category => '2.ACL',
    :order => 2
  }

  attribute 'http_access_deny',
  :description => "Http Access Deny",
  :data_type => 'array',
  :default => '[]',
  :format => {
    :help => 'Http Access Deny format <acl_name>. Ex: all',
    :category => '2.ACL',
    :order => 3
  }

attribute 'port',
  :description => "Listen Port",
  :required => "required",
  :default => "3128",
  :format => {
    :help => 'TCP port squid should listen on',
    :category => '3.Global',
    :order => 1
  }

attribute 'read_timeout',
  :description => "Read Timeout",
  :default => '10',
  :format => {
    :help => 'Read Timeout',
    :category => '3.Global',
    :order => 2
  }

# caching
attribute 'cache_dir',
  :description => "Cache Directory",
  :default => '/var/spool/squid',
  :format => {
    :help => 'Cache directory',
    :category => '4.Caching',
    :order => 1
  }

attribute 'cache_mem',
  :description => "Cache Memory",
  :default => "1024",
  :format => {
    :help => 'Cache memory in MB',
    :category => '4.Caching',
    :order => 2
  }

attribute 'cache_size',
  :description => "Cache Size",
  :default => "8092",
  :format => {
    :help => 'Cache size in MB',
    :category => '4.Caching',
    :order => 3
  }

attribute 'maximum_object_size',
  :description => "Maximum Object Size",
  :default => "512",
  :format => {
    :help => 'Maximum file size in MB',
    :category => '4.Caching',
    :order => 4
  }

recipe "start", "Start Squid"
recipe "stop", "Stop Squid"
recipe "restart", "Restart Squid"
recipe "reload", "Reload Squid"
recipe "repair", "Repair Squid"
