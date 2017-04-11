include_pack "genericlb"

name "rabbitmq"
description "RabbitMQ"
type "Platform"
category "Messaging"

platform :attributes => {'autoreplace' => 'false'}

resource 'compute',
         :cookbook => 'oneops.1.compute',
         :attributes => {'size' => 'M'
         }

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => "1..1"},
         :attributes => {
             :username => 'app',
             :description => 'App User',
             :home_directory => '/app',
             :system_account => true,
             :sudoer => true
         }
  
resource "rabbitmq_server",
  :cookbook => "oneops.1.rabbitmq_server",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "*mirror" }

resource "rabbitmq_cluster",
  :cookbook => "oneops.1.rabbitmq_cluster",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :payloads => { 'RequiresOs' => {
    'description' => 'os',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Rabbitmq_cluster",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "from",
           "targetClassName": "manifest.oneops.1.Os",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Os"
             }
           ]
         }
       ]
    }'
  },
  'RequiresKeys' => {
    'description' => 'keys',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Rabbitmq_cluster",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "from",
               "targetClassName": "manifest.oneops.1.Keypair",
               "relations": [
                   {"returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.RealizedAs",
                   "direction": "from",
                   "targetClassName": "bom.oneops.1.Keypair" 
                   }  
                ]
             }
           ]
         }
       ]
    }'
  }
}

resource "volume-data",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/data',
                    "device"        => '',
                    "size"          => '10G',
                    "fstype"        => 'ext4',
                    "options"       => ''                     
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
                }
    }

resource "volume-log",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/log',
                    "size"          => '100%FREE',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => ''
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

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "5672 5672 tcp 0.0.0.0/0", "5673 5673 tcp 0.0.0.0/0", "15672 15672 tcp 0.0.0.0/0", "25672 25672 tcp 0.0.0.0/0", "4369 4369 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

# depends_on
[{:from => 'os', :to => 'compute'},
  {:from => 'user-app', :to => 'os'},
  {:from => 'volume-data', :to => 'user-app'},
  {:from => 'volume-log', :to => 'volume-data'},
  {:from => 'volume-log', :to => 'user-app'},
  {:from => 'rabbitmq_server', :to => 'volume-log'},
  {:from => 'rabbitmq_cluster', :to => 'os'},
  {:from => 'rabbitmq_cluster', :to => 'rabbitmq_server'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# managed_via
[ 'user-app', 'volume-log', 'volume-data', 'rabbitmq_server', 'rabbitmq_cluster'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
