include_pack "base"

name "lbdb"
description "LB fronted Database"
type "Platform"
ignore true
category "Generic"


resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" }

resource "database",
  :cookbook => "oneops.1.database",
  :design => true,
  :requires => { "constraint" => "1..*" },
  :attributes => {  "dbname"        => 'mydb',
                    "username"      => 'myuser',
                    "password"      => 'mypassword' }

resource "volume",
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {
    "mount_point"   => '/db',
    "fstype"        => 'xfs'    
  },  
  :monitors => {
      'usage' =>  {'description' => 'Usage', 
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),                
                    'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),                
                  },                 
                },                  
    }

resource "lb",
  :except => [ 'single' ],
  :cookbook => "oneops.1.lb",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "lb,dns" },
  :attributes => {
    "stickiness"    => ""
  },
  :payloads => { 
  'primaryactiveclouds' => {
      'description' => 'primaryactiveclouds', 
      'definition' => '{ 
         "returnObject": false,
         "returnRelation": false, 
         "relationName": "base.RealizedAs", 
         "direction": "to", 
         "targetClassName": "manifest.Lb", 
         "relations": [ 
           { "returnObject": false, 
             "returnRelation": false, 
             "relationName": "manifest.Requires", 
             "direction": "to",
             "targetClassName": "manifest.Platform", 
             "relations": [ 
               { "returnObject": false, 
                 "returnRelation": false, 
                 "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                  {"attributeName":"adminstatus", "condition":"eq", "avalue":"active"}],
                 "relationName": "base.Consumes", 
                 "direction": "from",
                 "targetClassName": "account.Cloud",
                 "relations": [ 
                   { "returnObject": true, 
                     "returnRelation": false, 
                     "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"lb"}],
                     "relationName": "base.Provides", 
                     "direction": "from",
                     "targetClassName": "cloud.service.Netscaler"
                   }
                 ]                                  
               }
             ]
           } 
         ] 
      }'  
    },
    'stonithlbservice' => {
      'description' => 'Stonith lb service for creds', 
      'definition' => '{
         "returnObject": false, 
         "returnRelation": false, 
         "relationName": "base.RealizedAs", 
         "direction": "to", 
         "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"}],
         "targetClassName": "manifest.oneops.1.Lb", 
         "relations": [ 
           { "returnObject": false, 
             "returnRelation": false, 
             "relationName": "base.RealizedAs", 
             "direction": "from",
             "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"2"}],
             "targetClassName": "bom.oneops.1.Lb",
             "relations": [ 
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "base.DeployedTo",
                 "targetClassName": "account.Cloud",
                 "direction": "from",
                 "relations": [
                   {"returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"lb"}],
                   "direction": "from"
                   }
                 ]
               }
             ]
           } 
         ] 
      }'  
    },
    'stonithlb' => {
      'description' => 'Stonith LBs for servicegroups and lbvservers', 
      'definition' => '{
         "returnObject": false, 
         "returnRelation": false, 
         "relationName": "base.RealizedAs", 
         "direction": "to", 
         "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"}],
         "targetClassName": "manifest.oneops.1.Lb", 
         "relations": [ 
           { "returnObject": true, 
             "returnRelation": false, 
             "relationName": "base.RealizedAs", 
             "direction": "from",
             "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"2"}],
             "targetClassName": "bom.oneops.1.Lb"
           } 
         ] 
      }'  
    }    
  }  
    
resource "lb-certificate",
  :cookbook => "oneops.1.certificate",
  :design => true,
  :requires => { "constraint" => "0..1" },
  :attributes => {}



# DependsOn
[ 'build' ].each do |from|
  relation "#{from}::depends_on::database",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'database',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'database' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


[ 'lb' ].each do |from|
  relation "#{from}::depends_on::lb-certificate",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource => 'lb-certificate',
    :attributes => { "propagate_to" => 'from', "flex" => false, "min" => 0, "max" => 1 }
end


# depends_on
[ 'lb' ].each do |from|
  relation "#{from}::depends_on::compute",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :design => true,
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "min" => 1, "max" => 1} 
end


[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::lb",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 } 
end


# ManagedVia
[ 'database', 'build'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end

