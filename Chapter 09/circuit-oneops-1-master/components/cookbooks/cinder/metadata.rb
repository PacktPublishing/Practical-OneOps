name             "Cinder"
description      "Storage Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.storage', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'endpoint',
  :description => "API Endpoint",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Endpoint URL',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'tenant',
  :description => "Tenant",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Tenant Name',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Username',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Password',
    :category => '1.Authentication',
    :order => 4
  }

#
# limits
#
    
attribute 'max_total_volume_gigabytes',
  :description => "Max Total Volume Gigabytes",
  :default => '',
  :format => {
    :help => 'Max total volume gigabytes for tenant',
    :category => '2.Quota',
    :order => 1,
    :editable => false
  }  

attribute 'total_gigabytes_used',
  :description => "Total Gigabytes Used",
  :default => '',
  :format => {
    :help => 'Total gigabytes used for tenant',
    :category => '2.Quota',
    :order => 2,
    :editable => false
  }      

attribute 'max_total_volumes',
  :description => "Max Total Volumes",
  :default => '',
  :format => {
    :help => 'Max total volumes for tenant',
    :category => '2.Quota',
    :order => 3,
    :editable => true
  }      

attribute 'total_volumes_used',
  :description => "Total Volumes Used",
  :default => '',
  :format => {
    :help => 'Total volumes used for tenant',
    :category => '2.Quota',
    :order => 4,
    :editable => false
  }

attribute 'max_total_backup_gigabytes',
  :description => "Max Total Backup Gigabytes",
  :default => '',
  :format => {
    :help => 'Max total backup gigabytes for tenant',
    :category => '2.Quota',
    :order => 5,
    :editable => false
  }
    
attribute 'total_backup_gigabytes_used',
  :description => "Total Backup Gigabytes Used",
  :default => '',
  :format => {
    :help => 'Total backup gigabytes used for tenant',
    :category => '2.Quota',
    :order => 6,
    :editable => false
  }    

attribute 'max_total_backups',
  :description => "Max Total Backups",
  :default => '',
  :format => {
    :help => 'Max total backups for tenant',
    :category => '2.Quota',
    :order => 7,
    :editable => false
  }  
  
attribute 'total_backups_used',
  :description => "Total Backups Used",
  :default => '',
  :format => {
    :help => 'Total backups used for tenant',
    :category => '2.Quota',
    :order => 8,
    :editable => false
  }    
    
attribute 'max_total_snapshots',
  :description => "Max Total Snapshots",
  :default => '',
  :format => {
    :help => 'Max total snapshots for tenant',
    :category => '2.Quota',
    :order => 9,
    :editable => false
  }  

attribute 'total_snapshots_used',
  :description => "Total Snapshots Used",
  :default => '',
  :format => {
    :help => 'Total snapshots used for tenant',
    :category => '2.Quota',
    :order => 10,
    :editable => false
  }    

attribute 'volumetypemap',
  :description => "Volume Type Map",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of generic volume types to provider specific',
    :category => '3.Mappings',
    :order => 1
  }   

          
recipe "validate", "Validate Service Configuration"
recipe "status", "Check Service Status"
