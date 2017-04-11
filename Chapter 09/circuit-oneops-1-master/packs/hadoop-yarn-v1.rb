include_pack "base"
name "hadoop-yarn-v1"
description "Hadoop YARN (v1 build)"
type "Platform"
category "Hadoop"

# security group aka firewall
resource "secgroup",
    :cookbook => "oneops.1.secgroup",
    :design => true,
    :attributes => {
        "inbound" => '[
            "22 22 tcp 0.0.0.0/0",
            "1024 65535 tcp 0.0.0.0/0",
            "60000 60100 udp 0.0.0.0/0",
            "null null 4 0.0.0.0/0"
        ]'
    },
    :requires => {
        :constraint => "1..1",
        :services => "compute"
    }

#         _       _                          _
#        | |     | |                        | |
#      __| | __ _| |_ __ _   _ __   ___   __| | ___
#     / _` |/ _` | __/ _` | | '_ \ / _ \ / _` |/ _ \
#    | (_| | (_| | || (_| | | | | | (_) | (_| |  __/
#     \__,_|\__,_|\__\__,_| |_| |_|\___/ \__,_|\___|
#    data node

# admin user component
resource "dn-admin-user",
    :cookbook => "oneops.1.user",
    :design => true,
    :requires => { "constraint" => "0..*" },
    :attributes => {
        "username" => "someuser",
        "description" => "someuser",
        "sudoer" => true
    }

# work volume- this is the volume that hdfs will use for ephemeral storage including temp space
resource "dn-work-volume",
    :cookbook => "oneops.1.volume",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute" },
    :attributes => {
        "mount_point"   => '/work',
        "size"          => '100%FREE',
        "device"        => '',
        "fstype"        => 'ext4',
        "options"       => ''
    },
    # default built-in oneops monitors
    :monitors => {
        'usage' =>  {
            'description' => 'Usage',
            'chart' => { 'min'=>0,'unit'=> 'Percent used' },
            'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
            'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
            'metrics' => {
                'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
            },
            :thresholds => {
                'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            }
        }
    }

# compute specific for data nodes
resource "compute",
    :cookbook => "oneops.1.compute",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute,dns" },
    :attributes => { "size" => "S" },
    # default built-in oneops monitors
    :monitors => {
        'ssh' =>  {
            :description => 'SSH Port',
            :chart => { 'min'=>0 },
            :cmd => 'check_port',
            :cmd_line => '/opt/nagios/libexec/check_port.sh',
            :heartbeat => true,
            :duration => 5,
            :metrics =>  { 'up'  => metric( :unit => '%', :description => 'Up %') },
            :thresholds => { },
        }
    },
    :payloads => {
        'os' => {
            'description' => 'os',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Compute",
                "relations": [{
                    "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Os"
                }]
            }'
        }
    }

# os resource for data nodes
resource "os",
    :cookbook => "oneops.1.os",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
    :attributes => {
        "ostype"  => "centos-7.0",
        "dhclient"  => 'true'
    },
    # default built-in oneops monitors
    :monitors => {
        'cpu' =>  {
            :description => 'CPU',
            :source => '',
            :chart => { 'min'=>0,'max'=>100,'unit'=>'Percent' },
            :cmd => 'check_local_cpu!10!5',
            :cmd_line => '/opt/nagios/libexec/check_cpu.sh $ARG1$ $ARG2$',
            :metrics =>  {
                'CpuUser'   => metric( :unit => '%', :description => 'User %'),
                'CpuNice'   => metric( :unit => '%', :description => 'Nice %'),
                'CpuSystem' => metric( :unit => '%', :description => 'System %'),
                'CpuSteal'  => metric( :unit => '%', :description => 'Steal %'),
                'CpuIowait' => metric( :unit => '%', :description => 'IO Wait %'),
                'CpuIdle'   => metric( :unit => '%', :description => 'Idle %', :display => false)
            },
            :thresholds => {
                'HighCpuPeak' => threshold('5m','avg','CpuIdle',trigger('<=',10,5,1),reset('>',20,5,1)),
                'HighCpuUtil' => threshold('1h','avg','CpuIdle',trigger('<=',20,60,1),reset('>',30,60,1))
            }
        },
        'load' =>  {
            :description => 'Load',
            :chart => { 'min'=>0 },
            :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
            :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
            :duration => 5,
            :metrics =>  {
                'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                'load15' => metric( :unit => '', :description => 'Load 15min Average'),
            },
            :thresholds => { },
        },
        'disk' =>  {
            'description' => 'Disk',
            'chart' => {'min'=>0,'unit'=> '%'},
            'cmd' => 'check_disk_use!/',
            'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
            'metrics' => {
                'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
            },
            :thresholds => {
                'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            },
        },
        'mem' =>  {
            'description' => 'Memory',
            'chart' => {'min'=>0,'unit'=>'KB'},
            'cmd' => 'check_local_mem!90!95',
            'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
            'metrics' =>  {
                'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
            },
            :thresholds => { },
        },
        'network' => {
            :description => 'Network',
            :source => '',
            :chart => {'min' => 0, 'unit' => ''},
            :cmd => 'check_network_bandwidth',
            :cmd_line => '/opt/nagios/libexec/check_network_bandwidth.sh',
            :metrics => {
                'rx_bytes' => metric(:unit => 'bytes', :description => 'RX Bytes', :dstype => 'DERIVE'),
                'tx_bytes' => metric(:unit => 'bytes', :description => 'TX Bytes', :dstype => 'DERIVE')
            }
        }
    },
    :payloads => {
        'linksto' => {
            'description' => 'LinksTo',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "relations": [{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.Requires",
                    "direction": "to",
                    "targetClassName": "manifest.Platform",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.LinksTo",
                        "direction": "from",
                        "targetClassName": "manifest.Platform",
                        "relations": [{
                            "returnObject": true,
                            "returnRelation": false,
                            "relationName": "manifest.Entrypoint",
                            "direction": "from"
                        }]
                    }]
                }]
            }'
        }
    }

# main resource that sets up the comptues as data nodes
resource "dn-hadoop-yarn",
    :cookbook => "oneops.1.hadoop-yarn-v1",
    :design => false,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "data node"
    },
    # custom payloads
    :payloads => {
        # payload to use shared config among all the cluster components
        'yarnconfigci' => {
            'description' => 'hadoop yarn configurations',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                "relations": [{
                    "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "from",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-config-v1"
                }]
            }'
        },
        # payload to feed in the fqdns of all computes in an env for host-based key auth
        'allFqdn' => {
            'description' => 'All Fqdns',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                "relations": [{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.Requires",
                    "direction": "To",
                    "targetClassName": "manifest.Platform",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.Requires",
                        "direction": "from",
                        "targetClassName": "manifest.oneops.1.Fqdn",
                        "relations": [{
                            "returnObject": true,
                            "returnRelation": false,
                            "relationName": "base.RealizedAs",
                            "direction": "from",
                            "targetClassName": "bom.oneops.1.Fqdn"
                        }]
                    }]
                }]
            }'
        }
     }

# configures infoblox to add dns records
resource "hostname",
    :cookbook => "oneops.1.fqdn",
    :design => false,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "optional hostname dns entry"
    }

# java component
resource 'java',
    :cookbook   => 'oneops.1.java',
    :design     => true,
    :requires   => {
        :constraint => '1..1',
        :services   => '*mirror',
        :help       => 'Java Programming Language Environment'
    },
    :attributes => {
        :flavor => 'oracle',
        :jrejdk    => 'server-jre'
    }

# this is used strictly as a means to scale the data nodes
resource "lb",
    :except => [ 'single' ],
    :design => false,
    :cookbook => "oneops.1.lb",
    :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
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
                                  {"attributeName":"adminstatus", "condition":"neq", "avalue":"offline"}],
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
    }
    }

# required by lb resource
resource "lb-certificate",
    :cookbook => "oneops.1.certificate",
    :design => true,
    :requires => { "constraint" => "0..1" },
    :attributes => {}

# dependencies
[
    { :from => 'dn-admin-user', :to => 'os' },
    { :from => 'dn-work-volume', :to => 'os' },
    { :from => 'dn-hadoop-yarn', :to => 'dn-work-volume' },
    { :from => 'dn-hadoop-yarn', :to => 'java' },
    { :from => 'hostname', :to => 'os' },
    { :from => 'os', :to => 'compute' },
    { :from => 'java', :to => 'os' }
].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# prm needs to be configured and started before data nodes
[{ :from => 'dn-hadoop-yarn', :to => 'prm-hadoop-yarn' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# this is an inroad for the custom payload for the configs to follow
[{ :from => 'dn-hadoop-yarn', :to => 'hadoop-yarn-config' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# overrides default of current data nodes to use 3 instead of only 2
[ 'lb' ].each do |from|
    relation "#{from}::depends_on::dn-hadoop-yarn",
        :except => [ '_default', 'single' ],
        :relation_name => 'DependsOn',
        :from_resource => from,
        :to_resource   => 'dn-hadoop-yarn',
        :attributes    => { "propagate_to" => 'from', "flex" => true, "current" =>3, "min" => 3, "max" => 10}
end

# this is required for the lb resource
[ 'lb' ].each do |from|
    relation "#{from}::depends_on::lb-certificate",
        :except => [ '_default', 'single' ],
        :relation_name => 'DependsOn',
        :from_resource => from,
        :to_resource => 'lb-certificate',
        :attributes => { "propagate_to" => 'from', "flex" => false, "min" => 0, "max" => 1 }
end

# by default the lb resource depends on the fqdn component
[ 'fqdn' ].each do |from|
    relation "#{from}::depends_on::lb",
        :except => [ '_default', 'single' ],
        :relation_name => 'DependsOn',
        :from_resource => from,
        :to_resource   => 'lb',
        :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via (this specifies where the resources are run)
[
    { :from => 'dn-admin-user', :to => 'compute' },
    { :from => 'dn-work-volume', :to => 'compute' },
    { :from => 'java', :to => 'compute' },
    { :from => 'dn-hadoop-yarn', :to => 'compute' },
    { :from => 'lb', :to => 'compute' }
].each do |link|
    relation "#{link[:from]}::managed_via::#{link[:to]}",
        :except        => [ '_default' ],
        :relation_name => 'ManagedVia',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { }
end

#                _
#     _ __  _ __(_)_ __ ___   __ _ _ __ _   _   _ __ _ __ ___
#    | '_ \| '__| | '_ ` _ \ / _` | '__| | | | | '__| '_ ` _ \
#    | |_) | |  | | | | | | | (_| | |  | |_| | | |  | | | | | |
#    | .__/|_|  |_|_| |_| |_|\__,_|_|   \__, | |_|  |_| |_| |_|
#    |_|                                |___/
#    primary resource manager

# admin user component
resource "prm-admin-user",
    :cookbook => "oneops.1.user",
    :design => true,
    :requires => { "constraint" => "0..*" },
    :attributes => {
        "username" => "someuser",
        "description" => "someuser",
        "sudoer" => true
    }

# work volume- this is the volume that hdfs will use for ephemeral storage including temp space
resource "prm-work-volume",
    :cookbook => "oneops.1.volume",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute" },
    :attributes => {
        "mount_point"   => '/work',
        "size"          => '100%FREE',
        "device"        => '',
        "fstype"        => 'ext4',
        "options"       => ''
    },
    :monitors => {
        'usage' =>  {
            'description' => 'Usage',
            'chart' => { 'min'=>0,'unit'=> 'Percent used' },
            'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
            'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
            'metrics' => {
                'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
            },
            :thresholds => {
                'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            }
        }
    }

# compute specific for resource manager
resource "prm-compute",
    :cookbook => "oneops.1.compute",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute,dns" },
    :attributes => { "size" => "S" },
    # default built-in oneops monitors
    :monitors => {
        'ssh' =>  {
            :description => 'SSH Port',
            :chart => { 'min'=>0 },
            :cmd => 'check_port',
            :cmd_line => '/opt/nagios/libexec/check_port.sh',
            :heartbeat => true,
            :duration => 5,
            :metrics =>  { 'up'  => metric( :unit => '%', :description => 'Up %') },
            :thresholds => { },
        }
    },
    :payloads => {
        'os' => {
            'description' => 'os',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Compute",
                "relations": [{
                    "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Os"
                }]
            }'
        }
    }

# os resource for resource manager
resource "prm-os",
    :cookbook => "oneops.1.os",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
    :attributes => {
        "ostype"  => "centos-7.0",
        "dhclient"  => 'true'
    },
    # default built-in oneops monitors
    :monitors => {
        'cpu' =>  {
            :description => 'CPU',
            :source => '',
            :chart => { 'min'=>0,'max'=>100,'unit'=>'Percent' },
            :cmd => 'check_local_cpu!10!5',
            :cmd_line => '/opt/nagios/libexec/check_cpu.sh $ARG1$ $ARG2$',
            :metrics =>  {
                'CpuUser'   => metric( :unit => '%', :description => 'User %'),
                'CpuNice'   => metric( :unit => '%', :description => 'Nice %'),
                'CpuSystem' => metric( :unit => '%', :description => 'System %'),
                'CpuSteal'  => metric( :unit => '%', :description => 'Steal %'),
                'CpuIowait' => metric( :unit => '%', :description => 'IO Wait %'),
                'CpuIdle'   => metric( :unit => '%', :description => 'Idle %', :display => false)
            },
            :thresholds => {
                'HighCpuPeak' => threshold('5m','avg','CpuIdle',trigger('<=',10,5,1),reset('>',20,5,1)),
                'HighCpuUtil' => threshold('1h','avg','CpuIdle',trigger('<=',20,60,1),reset('>',30,60,1))
            }
        },
        'load' =>  {
            :description => 'Load',
            :chart => { 'min'=>0 },
            :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
            :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
            :duration => 5,
            :metrics =>  {
                'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                'load15' => metric( :unit => '', :description => 'Load 15min Average'),
            },
            :thresholds => { },
        },
        'disk' =>  {
            'description' => 'Disk',
            'chart' => {'min'=>0,'unit'=> '%'},
            'cmd' => 'check_disk_use!/',
            'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
            'metrics' => {
                'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
            },
            :thresholds => {
                'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            },
        },
        'mem' =>  {
            'description' => 'Memory',
            'chart' => {'min'=>0,'unit'=>'KB'},
            'cmd' => 'check_local_mem!90!95',
            'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
            'metrics' =>  {
                'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
            },
            :thresholds => { },
        },
        'network' => {
            :description => 'Network',
            :source => '',
            :chart => {'min' => 0, 'unit' => ''},
            :cmd => 'check_network_bandwidth',
            :cmd_line => '/opt/nagios/libexec/check_network_bandwidth.sh',
            :metrics => {
                'rx_bytes' => metric(:unit => 'bytes', :description => 'RX Bytes', :dstype => 'DERIVE'),
                'tx_bytes' => metric(:unit => 'bytes', :description => 'TX Bytes', :dstype => 'DERIVE')
            }
        }
    },
    :payloads => {
        'linksto' => {
            'description' => 'LinksTo',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "relations": [{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.Requires",
                    "direction": "to",
                    "targetClassName": "manifest.Platform",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.LinksTo",
                        "direction": "from",
                        "targetClassName": "manifest.Platform",
                        "relations": [{
                            "returnObject": true,
                            "returnRelation": false,
                            "relationName": "manifest.Entrypoint",
                            "direction": "from"
                        }]
                    }]
                }]
            }'
        }
    }

# main resource that sets up resource manager and name node
resource "prm-hadoop-yarn",
    :cookbook => "oneops.1.hadoop-yarn-v1",
    :design => false,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "resource manager"
    },
    # custom payloads
    :payloads => {
        # payload to use shared config among all the cluster components
        'yarnconfigci' => {
            'description' => 'hadoop yarn configurations',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                "relations": [{
                    "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "from",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-config-v1"
                }]
            }'
        },
        # payload to feed in the fqdns of all computes in an env for host-based key auth
        'allFqdn' => {
            'description' => 'All Fqdns',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                "relations": [{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.Requires",
                    "direction": "To",
                    "targetClassName": "manifest.Platform",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.Requires",
                        "direction": "from",
                        "targetClassName": "manifest.oneops.1.Fqdn",
                        "relations": [{
                            "returnObject": true,
                            "returnRelation": false,
                            "relationName": "base.RealizedAs",
                            "direction": "from",
                            "targetClassName": "bom.oneops.1.Fqdn"
                        }]
                    }]
                }]
            }'
        }
     }

# configures infoblox to add dns records
resource "prm-hostname",
    :cookbook => "oneops.1.fqdn",
    :design => true,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "optional hostname dns entry"
    }

# java component
resource 'prm-java',
    :cookbook   => 'oneops.1.java',
    :design     => true,
    :requires   => {
        :constraint => '1..1',
        :services   => '*mirror',
        :help       => 'Java Programming Language Environment'
    },
    :attributes => {
        :flavor => 'oracle',
        :jrejdk    => 'server-jre'
    }

# dependencies
# the resource manager needs explicit security group dependency because of the custom compute name
[{ :from => 'prm-compute', :to => 'secgroup' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

[
    { :from => 'prm-admin-user', :to => 'prm-os' },
    { :from => 'prm-work-volume', :to => 'prm-os' },
    { :from => 'prm-hadoop-yarn', :to => 'prm-work-volume' },
    { :from => 'prm-hostname', :to => 'prm-os' },
    { :from => 'prm-os', :to => 'prm-compute' },
    { :from => 'prm-hadoop-yarn', :to => 'prm-java' },
    { :from => 'prm-java', :to => 'prm-os' }
].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# compute needs to be in place before dns is set up, because ip
[{ :from => 'prm-hostname', :to => 'prm-compute' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# this is an inroad for the custom payload for the configs to follow
[{ :from => 'prm-hadoop-yarn', :to => 'hadoop-yarn-config' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# managed_via (this specifies where the resources are run)
[
    { :from => 'prm-admin-user', :to => 'prm-compute' },
    { :from => 'prm-work-volume', :to => 'prm-compute' },
    { :from => 'prm-os', :to => 'prm-compute' },
    { :from => 'prm-java', :to => 'prm-compute' },
    { :from => 'prm-hadoop-yarn', :to => 'prm-compute' }
].each do |link|
    relation "#{link[:from]}::managed_via::#{link[:to]}",
        :except        => [ '_default' ],
        :relation_name => 'ManagedVia',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { }
end

# this specifies that oo will initially manage the computes via ssh key
relation "prm-compute::secured_by::sshkeys",
    :except        => ['_default', 'single'],
    :relation_name => 'SecuredBy',
    :from_resource => 'prm-compute',
    :to_resource   => 'sshkeys',
    :attributes    => {}

#          _ _            _
#         | (_)          | |
#      ___| |_  ___ _ __ | |_
#     / __| | |/ _ \ '_ \| __|
#    | (__| | |  __/ | | | |_
#     \___|_|_|\___|_| |_|\__|
#     client

# sets up user account on client
resource "client-user",
    :cookbook => "oneops.1.user",
    :design => true,
    :requires => { "constraint" => "0..*" },
    :attributes => {
        "username" => "someuser",
        "description" => "someuser",
        "sudoer" => true
    }

# work volume- this is the volume that hdfs will use for ephemeral storage including temp space
resource "client-work-volume",
    :cookbook => "oneops.1.volume",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute" },
    :attributes => {
        "mount_point"   => '/work',
        "size"          => '100%FREE',
        "device"        => '',
        "fstype"        => 'ext4',
        "options"       => ''
    },
    # default built-in oneops monitors
    :monitors => {
        'usage' =>  {
            'description' => 'Usage',
            'chart' => { 'min'=>0,'unit'=> 'Percent used' },
            'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
            'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
            'metrics' => {
                'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
            },
            :thresholds => {
                'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            }
        }
    }

# compute specific for client
resource "client-compute",
    :cookbook => "oneops.1.compute",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute,dns" },
    :attributes => { "size" => "S" },
    # default built-in oneops monitors
    :monitors => {
        'ssh' =>  {
            :description => 'SSH Port',
            :chart => { 'min'=>0 },
            :cmd => 'check_port',
            :cmd_line => '/opt/nagios/libexec/check_port.sh',
            :heartbeat => true,
            :duration => 5,
            :metrics =>  { 'up'  => metric( :unit => '%', :description => 'Up %') },
            :thresholds => { },
        }
    },
    :payloads => {
        'os' => {
            'description' => 'os',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Compute",
                "relations": [{
                    "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Os"
                }]
            }'
        }
    }

# os resource for client
resource "client-os",
    :cookbook => "oneops.1.os",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
    :attributes => {
        "ostype"  => "centos-7.0",
        "dhclient"  => 'true'
    },
    # default built-in oneops monitors
    :monitors => {
        'cpu' =>  {
            :description => 'CPU',
            :source => '',
            :chart => { 'min'=>0,'max'=>100,'unit'=>'Percent' },
            :cmd => 'check_local_cpu!10!5',
            :cmd_line => '/opt/nagios/libexec/check_cpu.sh $ARG1$ $ARG2$',
            :metrics =>  {
                'CpuUser'   => metric( :unit => '%', :description => 'User %'),
                'CpuNice'   => metric( :unit => '%', :description => 'Nice %'),
                'CpuSystem' => metric( :unit => '%', :description => 'System %'),
                'CpuSteal'  => metric( :unit => '%', :description => 'Steal %'),
                'CpuIowait' => metric( :unit => '%', :description => 'IO Wait %'),
                'CpuIdle'   => metric( :unit => '%', :description => 'Idle %', :display => false)
            },
            :thresholds => {
                'HighCpuPeak' => threshold('5m','avg','CpuIdle',trigger('<=',10,5,1),reset('>',20,5,1)),
                'HighCpuUtil' => threshold('1h','avg','CpuIdle',trigger('<=',20,60,1),reset('>',30,60,1))
            }
        },
        'load' =>  {
            :description => 'Load',
            :chart => { 'min'=>0 },
            :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
            :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
            :duration => 5,
            :metrics =>  {
                'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                'load15' => metric( :unit => '', :description => 'Load 15min Average'),
            },
            :thresholds => { },
        },
        'disk' =>  {
            'description' => 'Disk',
            'chart' => {'min'=>0,'unit'=> '%'},
            'cmd' => 'check_disk_use!/',
            'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
            'metrics' => {
                'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
            },
            :thresholds => {
                'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            },
        },
        'mem' =>  {
            'description' => 'Memory',
            'chart' => {'min'=>0,'unit'=>'KB'},
            'cmd' => 'check_local_mem!90!95',
            'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
            'metrics' =>  {
                'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
            },
            :thresholds => { },
        },
        'network' => {
            :description => 'Network',
            :source => '',
            :chart => {'min' => 0, 'unit' => ''},
            :cmd => 'check_network_bandwidth',
            :cmd_line => '/opt/nagios/libexec/check_network_bandwidth.sh',
            :metrics => {
                'rx_bytes' => metric(:unit => 'bytes', :description => 'RX Bytes', :dstype => 'DERIVE'),
                'tx_bytes' => metric(:unit => 'bytes', :description => 'TX Bytes', :dstype => 'DERIVE')
            }
        }
    },
    :payloads => {
        'linksto' => {
            'description' => 'LinksTo',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "relations": [{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.Requires",
                    "direction": "to",
                    "targetClassName": "manifest.Platform",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.LinksTo",
                        "direction": "from",
                        "targetClassName": "manifest.Platform",
                        "relations": [{
                            "returnObject": true,
                            "returnRelation": false,
                            "relationName": "manifest.Entrypoint",
                            "direction": "from"
                        }]
                    }]
                }]
            }'
        }
    }

# main resource that sets up yarn client
resource "client-hadoop-yarn",
    :cookbook => "oneops.1.hadoop-yarn-v1",
    :design => false,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "resource manager"
    },
    # custom payloads
    :payloads => {
        # payload to use shared config among all the cluster components
        'yarnconfigci' => {
            'description' => 'hadoop yarn configurations',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                "relations": [{
                    "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "from",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-config-v1"
                }]
            }'
        },
        # payload to feed in the fqdns of all computes in an env for host-based key auth
        'allFqdn' => {
            'description' => 'All Fqdns',
            'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                "relations": [{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.Requires",
                    "direction": "To",
                    "targetClassName": "manifest.Platform",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.Requires",
                        "direction": "from",
                        "targetClassName": "manifest.oneops.1.Fqdn",
                        "relations": [{
                            "returnObject": true,
                            "returnRelation": false,
                            "relationName": "base.RealizedAs",
                            "direction": "from",
                            "targetClassName": "bom.oneops.1.Fqdn"
                        }]
                    }]
                }]
            }'
        }
     }

# stores all attributes to be used among the cluster components
resource "hadoop-yarn-config",
    :cookbook => "oneops.1.hadoop-yarn-config-v1",
    :design => true,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "client"
    }

# configures infoblox to add dns records
resource "client-hostname",
    :cookbook => "oneops.1.fqdn",
    :design => true,
    :requires => {
        :constraint => "1..1",
        :services => "dns",
        :help => "optional hostname dns entry"
    }

# java component
resource 'client-java',
    :cookbook   => 'oneops.1.java',
    :design     => true,
    :requires   => {
        :constraint => '1..1',
        :services   => '*mirror',
        :help       => 'Java Programming Language Environment'
    },
    :attributes => {
        :flavor => 'oracle',
        :jrejdk    => 'server-jre'
    }

# dependencies
# the client needs explicit security group dependency because of the custom compute name
[{ :from => 'client-compute', :to => 'secgroup' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

[
    { :from => 'client-user', :to => 'client-os' },
    { :from => 'client-work-volume', :to => 'client-os' },
    { :from => 'client-hadoop-yarn', :to => 'client-work-volume' },
    { :from => 'client-hostname', :to => 'client-os' },
    { :from => 'client-os', :to => 'client-compute' },
    { :from => 'client-hadoop-yarn', :to => 'client-java' },
    { :from => 'client-java', :to => 'client-os' }
].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# prm needs to be configured and started before the client
[{ :from => 'client-hadoop-yarn', :to => 'prm-hadoop-yarn' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# this is an inroad for the custom payload for the configs to follow
[{ :from => 'client-hadoop-yarn', :to => 'hadoop-yarn-config' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# compute needs to be in place before dns is set up, because ip
[{ :from => 'client-hostname', :to => 'client-compute' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
        :relation_name => 'DependsOn',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via (this specifies where the resources are run)
[
    { :from => 'client-user', :to => 'client-compute' },
    { :from => 'client-work-volume', :to => 'client-compute' },
    { :from => 'client-os', :to => 'client-compute' },
    { :from => 'client-java', :to => 'client-compute' },
    { :from => 'client-hadoop-yarn', :to => 'client-compute' }
].each do |link|
    relation "#{link[:from]}::managed_via::#{link[:to]}",
        :except        => [ '_default' ],
        :relation_name => 'ManagedVia',
        :from_resource => link[:from],
        :to_resource   => link[:to],
        :attributes    => { }
end

# this specifies that oo will initially manage the computes via ssh key
relation "client-compute::secured_by::sshkeys",
    :except        => ['_default', 'single'],
    :relation_name => 'SecuredBy',
    :from_resource => 'client-compute',
    :to_resource   => 'sshkeys',
    :attributes    => {}
