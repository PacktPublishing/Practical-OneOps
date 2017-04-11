include_pack "base"

name "generic_ring"
description "Generic Ring"
type "Platform"
ignore true
category "Generic"

resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" }

resource "volume",
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/data',
                    "device"        => '',
                    "fstype"        => 'xfs',
                    "options"       => 'noatime,nodiratime'  
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

resource "ring",
  :except => [ 'single' ],
  :cookbook => "oneops.1.ring",
  :design => false,
  :requires => { "constraint" => "1..1" }


# DependsOn
[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'ring',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 } 
end

# ManagedVia
[ 'ring', 'build' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end

# SecuredBy
[ 'ring'].each do |from|
  relation "#{from}::secured_by::sshkeys",
    :except => [ '_default','single'],
    :relation_name => 'SecuredBy',
    :from_resource => from,
    :to_resource   => 'sshkeys',
    :attributes    => { } 
end
