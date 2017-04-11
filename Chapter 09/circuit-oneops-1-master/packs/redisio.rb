include_pack "generic_ring"

name "redisio"
description "RedisIO"
type "Platform"
category "Database NoSQL"

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

#:src_url => '$OO_CLOUD{nexus}/nexus/service/local/repositories/thirdparty/content/redis/io/redis/'
resource "redisio",
  :cookbook => "oneops.1.redisio",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => 'Redis data structure server'
  }
#  },
#  :attributes => {
#    :src_url => '$OO_CLOUD{nexus}/nexus/content/repositories/thirdparty/redis/io/redis/'

#overwrite volume and filesystem from generic_ring with new mount point
resource "volume",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/app',
                    "size"          => '60%VG',
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
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "6379 6379 tcp 0.0.0.0/0", "16379 16379 tcp 0.0.0.0/0", "26379 26379 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }


# depends_on
[{:from => 'user-app', :to => 'compute'},
  {:from => 'user-app', :to => 'os'},
  {:from => 'volume', :to => 'user-app'},
  {:from => 'volume-log', :to => 'volume'},
  {:from => 'volume-log', :to => 'user-app'},
    {:from => 'redisio', :to => 'volume-log'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "ring::depends_on::redisio",
         :except => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'ring',
         :to_resource => 'redisio',
         :attributes => {"flex" => true, "min" => 6, "max" => 10}

# managed_via
['user-app', 'volume-log', 'volume-app', 'volume', 'redisio'].each do |from|

  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
