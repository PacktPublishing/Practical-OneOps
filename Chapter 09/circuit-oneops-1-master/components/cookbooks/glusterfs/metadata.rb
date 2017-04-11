name             "Glusterfs"
description      "GlusterFS"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => 'Version',
  :required => 'required',
  :default => '3.6',
  :format => {
    :important => true,
    :help => 'Glusterfs Version',
    :category => '1.Global',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['3.6', '3.6']]}
    }

attribute 'store',
  :description => "Volume Directory",
  :required => "required",
  :default => "/glusterfs",
  :format => {
    :help => 'The directory path where GlusterFS volumes will be stored',
    :category => '1.Global',
    :order => 1
  }

attribute 'volopts',
  :description => "Volume Options",
  :data_type => "hash",
  :default => "{}",
  :format => {
    :help => 'Volume options to be set',
    :category => '1.Global',
    :order => 2
  }

attribute 'replicas',
  :description => "Data Replicas",
  :required => "required",
  :default => "1",
  :format => {
    :help => 'Number of data replicas',
    :category => '1.Global',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [ ['1','1'],['2','2'],['3','3'] ] }
  }

attribute 'mount_point',
  :description => "Mount Point",
  :required => "required",
  :format => {
    :help => 'The path where the distributed filesystem should be mounted',
    :category => '1.Filesystem',
    :order => 1
  }
    
recipe "mount", "Mount"
recipe "repair", "Repair"