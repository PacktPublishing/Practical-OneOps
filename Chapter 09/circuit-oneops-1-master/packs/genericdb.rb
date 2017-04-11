include_pack "cluster"

name "genericdb"
description "Generic Database"
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
    :only => [ 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'database' ].each do |from|
  relation "#{from}::depends_on::cluster",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'cluster',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::cluster",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'cluster',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


# ManagedVia
[ 'database', 'build'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default', 'redundant' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end


[ 'database', 'build' ].each do |from|
  relation "#{from}::managed_via::cluster",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'cluster',
    :attributes    => { } 
end

