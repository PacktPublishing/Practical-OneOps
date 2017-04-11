name             "Nfs"
description      "Installs/Configures NFS server"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'exports',
  :description => "Exports",
  :data_type => "hash",
  :required => "required",
  :default => "{}",
  :format => {
    :help => 'List of directories that will be exported as NFS filesystems along with the options',
    :category => '1.Global',
    :order => 1
  }

recipe "status", "Nfs Status"
recipe "start", "Start Nfs"
recipe "stop", "Stop Nfs"
recipe "restart", "Restart Nfs"
recipe "repair", "Repair Nfs"
