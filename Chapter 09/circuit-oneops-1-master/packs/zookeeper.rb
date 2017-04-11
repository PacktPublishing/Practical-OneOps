include_pack 'generic_ring'

name "zookeeper"
description "Zookeeper"
type "Platform"
category "Other"

platform :attributes => {'autoreplace' => 'false'}

environment "single", {}
environment "redundant", {}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "2181 2182 tcp 0.0.0.0/0","2888 2888 tcp 0.0.0.0/0","3888 3888 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "zookeeper",
         :cookbook => "oneops.1.zookeeper",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {},
          :monitors => {
             'zookeeperprocess' => {:description => 'ZookeeperProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!zookeeper-server!false!QuorumPeerMain',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'ZookeeperProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                           }
             },
            'cluster_health' =>  {'description' => 'Cluster Health',
                  'chart' => {'min'=>0,'unit'=> 'Number'},
                  'cmd' => 'check_cluster_health',
                  'cmd_line' => '/opt/nagios/libexec/check_cluster_health.sh',
                  'metrics' => {
                        'return_code' => metric(:unit => 'count', :description => 'Return Code from script'),
                                 },
                  :thresholds => {
                    'ClusterHealth' => threshold('1m','avg','return_code',trigger('>',1,1,1),reset('<',1,1,1))
                  },
                }
          }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => {
             :constraint => "0..*",
             :help => "Artifact component"
         },
         :attributes => {
         }

resource "user-zookeeper",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "zookeeper",
             "description" => "App User",
             "home_directory" => "/zookeeper",
             "system_account" => true,
             "sudoer" => true
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {}


resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "dns",
    :help => "optional hostname dns entry"
  },
  # enable ptr and change ptr_source to 'instance'
  :attributes => {
    :ptr_enabled => "true",
    :ptr_source => "instance"
  }

resource "volume-log",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "0..1", "services" => "compute" },
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

resource "volume",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "0..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/data',
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

# depends_on
[
  {:from => 'volume-log', :to => 'compute'},
  {:from => 'volume-log', :to => 'volume'},
  {:from => 'volume', :to => 'os'},
  {:from => 'volume', :to => 'user-zookeeper'},
  {:from => 'volume', :to => 'compute'},
  {:from => 'java', :to => 'os'},
  {:from => 'user-zookeeper', :to => 'os'},
  {:from => 'java', :to => 'compute'},
  {:from => 'user-zookeeper', :to => 'compute'},
  {:from => 'zookeeper', :to => 'user-zookeeper'},
  {:from => 'artifact', :to => 'user-zookeeper'},
  {:from => 'artifact', :to => 'compute'},
  {:from => 'zookeeper', :to => 'volume-log'},
  {:from => 'zookeeper', :to => 'hostname'},
  {:from => 'zookeeper', :to => 'java'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

relation "ring::depends_on::zookeeper",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'zookeeper',
    :attributes    => {"flex" => true, "min" => 3, "max" => 10 }

# managed_via
[ 'zookeeper'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" }

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
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
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
# managed_via
['user-zookeeper', 'artifact', 'zookeeper', 'java', 'library', 'volume-log', 'volume'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
