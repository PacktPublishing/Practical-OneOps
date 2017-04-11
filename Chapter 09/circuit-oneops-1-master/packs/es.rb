include_pack 'genericlb'

name         'es'
description  'ElasticSearch With LB'
type         'Platform'
category     'Search Engine'

platform :attributes => {'autoreplace' => 'false'}

# Overriding the default compute
resource 'compute',
         :attributes => {
           'ostype' => 'default-cloud',
           'size' => 'M'
         }


resource "lb",
  :except => [ 'single' ],
  :design => true,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
  :attributes => {
    "listeners" => '["http 9200 http 9200"]',
    "ecv_map"   => "{\"9200\":\"GET /\"}"
}

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/home/app',
             'system_account' => true,
             'sudoer' => true
         }

# overwrite volume and filesystem from generic_ring with new mount point
resource 'volume',
         :requires => {'constraint' => '1..1', 'services' => 'compute'},
         :attributes => {'mount_point' => '/data',
                         'size' => '100%FREE',
                         'device' => '',
                         'fstype' => 'ext4',
                         'options' => ''
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


resource 'elasticsearch',
         :cookbook => 'oneops.1.es',
         :design => true,
         :requires => {'constraint' => '1..*', 'services' => 'mirror'},
         :attributes => {
             'version' => '1.7.1'
         },
         :monitors => {
             'Log' => {:description => 'Log',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_logfiles!logelasticsearch!:::node.workorder.rfcCi.ciAttributes.log_dir:::/:::node.workorder.rfcCi.ciAttributes.cluster_name:::.log!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                       :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                       :cmd_options => {
                           'warningpattern' => 'WARNING',
                           'criticalpattern' => 'CRITICAL'
                       },
                       :metrics => {
                           'logelasticsearch_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                           'logelasticsearch_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                           'logelasticsearch_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                           'logelasticsearch_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                       },
                       :thresholds => {
                         'CriticalLogException' => threshold('1m', 'avg', 'logelasticsearch_criticals', trigger('>=', 1, 5, 1), reset('<', 1, 15, 1)),
                       }
             },
             'ElasticSearchStats' => {
                 :description => 'elasticsearch_stats',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'status' => metric(:unit => '',:description => 'status',:dstype => 'GAUGE',:display_group => "Process Status"),
                     'indexed_doc_count' => metric(:unit => '', :description => 'doc_count', :dstype => 'DERIVE',:display_group => "Index"),
                     'search_rate' => metric(:unit => '', :description => 'search_rate', :dstype => 'GAUGE',:display_group => "Search"),
                     'filter_cache_evictions' => metric(:unit => '', :description => 'filter_cache_evictions', :dstype => 'GAUGE',:display_group => "Cache"),
                     'heap_used_percent' => metric(:unit => '%', :description => 'Heap used percent', :dstype => 'GAUGE',:display_group => "Jvm_Stats"),
                     'gc_old_collections' => metric(:unit => '', :description => 'gc_old_collections', :dstype => 'GUAGE',:display_group => "Jvm_Stats"),
                     'index_rejections' => metric(:unit => '', :description => 'index_rejections', :dstype => 'GAUGE',:display_group => "Index"),
                     'search_rejections' => metric(:unit => '', :description => 'search_rejections', :dstype => 'GAUGE',:display_group => "Search"),
                     'disk_reads' => metric(:unit => '', :description => 'disk_reads', :dstype => 'GAUGE',:display_group => "Disk"),
                     'disk_writes' => metric(:unit => '', :description => 'disk_writes', :dstype => 'GAUGE',:display_group => "Disk"),

                 },
                 :thresholds => {
                 }
             }
         }
         
resource 'index',
         :cookbook => 'oneops.1.index',
         :design => true,
         :requires => {'constraint' => '0..*','services' => 'compute'},
         :attributes => {
         }  
         
resource 'logstash',
         :cookbook => 'oneops.1.logstash',
         :design => true,
         :requires => {'constraint' => '0..1', 'services' => 'mirror'},
         :attributes => {
         },
         :monitors => {
             'logstashprocess' => {:description => 'LogstashProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!logstash!false!logstash/runner.rb',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'LogstashProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                           }
             }
          }       


resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "install_dir"   => '/usr/local/build',
    "repository"    => "",
    "remote"        => 'origin',
    "revision"      => 'HEAD',
    "depth"         => 1,
    "submodules"    => 'false',
    "environment"   => '{}',
    "persist"       => '[]',
    "migration_command" => '',
    "restart_command"   => ''
  }
  
resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }
  
resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "9200 9400 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }
  
resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "0..1",
    :services => "dns",
    :help => "optional hostname dns entry"
  }  
  
resource "haproxy",
  :cookbook => "oneops.1.haproxy",
  :design => true,
  :requires => { "constraint" => "0..1" },
  :monitors => {
      'stats' => {:description => 'stats',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_haproxy',
                     :cmd_line => '/opt/nagios/libexec/check_haproxy.rb',
                     # see http://www.haproxy.org/download/1.5/doc/configuration.txt for more detail
                     :metrics => {
                         'requests' => metric(:unit => 'req/sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                         'current_sessions' => metric(:unit => 'count', :description => 'Current Sessions', :dstype => 'GAUGE'),
                         'errors_req' => metric(:unit => 'errors_req/sec', :description => 'Error Requests /sec', :dstype => 'DERIVE'),
                         'errors_conn' => metric(:unit => 'errors_conn/sec', :description => 'Error Connections /sec', :dstype => 'DERIVE'),
                         'errors_resp' => metric(:unit => 'errors_resp/sec', :description => 'Error Resp /sec', :dstype => 'DERIVE'),
                         'bytes_in' => metric(:unit => 'bytes/sec', :description => 'Bytes in /sec', :dstype => 'DERIVE'),
                         'bytes_out' => metric(:unit => 'bytes/sec', :description => 'Bytes out /sec', :dstype => 'DERIVE')
                     }
           }
  }  
  
  
# depends_on
[
 {:from => 'elasticsearch', :to => 'user-app'},
 {:from => 'elasticsearch', :to => 'os'},
 {:from => 'java',          :to => 'os'},
 {:from => 'user-app',      :to => 'os'},
 {:from => 'haproxy',       :to => 'os'},
 {:from => 'elasticsearch', :to => 'volume'},
 {:from => 'elasticsearch', :to => 'java'  },
 {:from => 'elasticsearch', :to => 'hostname'},
 {:from => 'logstash',      :to => 'elasticsearch'},
 {:from => 'build',         :to => 'elasticsearch'},
 {:from => 'artifact',      :to => 'elasticsearch'},
 {:from => 'index',         :to => 'elasticsearch'},
 {:from => 'daemon',        :to => 'artifact'},
 {:from => 'daemon',        :to => 'build'}].each do |link|
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


# managed_via
['user-app','elasticsearch','logstash','artifact','java','haproxy'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end


resource 'master-compute',
         :cookbook => 'oneops.1.compute',
         :requires => {
             "constraint" => "0..1",
             "services" => "compute,dns,*ntp",
             "help" => "computes where master elastic search nodes will be deployed"
         },
         :attributes => {'ostype' => 'default-cloud',
                         'size' => 'M'
         },
         :monitors => {
             'ssh' =>  { :description => 'SSH Port',
                         :chart => {'min'=>0},
                         :cmd => 'check_port',
                         :cmd_line => '/opt/nagios/libexec/check_port.sh',
                         :heartbeat => true,
                         :duration => 5,
                         :metrics =>  {
                             'up'  => metric( :unit => '%', :description => 'Up %')
                         },
                         :thresholds => {
                         },
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
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.DependsOn",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Os"
           }
         ]
      }'}}

resource "master-os",
         :cookbook => "oneops.1.os",
         :design => true,
         :requires => { "constraint" => "0..1", "services" => "compute,dns,*ntp" },
         :attributes => { "ostype"  => "centos-7.0",
                          "dhclient"  => 'true'
         },
         :monitors => {
             'cpu' =>  { :description => 'CPU',
                         :source => '',
                         :chart => {'min'=>0,'max'=>100,'unit'=>'Percent'},
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
             'load' =>  { :description => 'Load',
                          :chart => {'min'=>0},
                          :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
                          :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
                          :duration => 5,
                          :metrics =>  {
                              'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                              'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                              'load15' => metric( :unit => '', :description => 'Load 15min Average'),
                          },
                          :thresholds => {
                          },
             },
             'disk' =>  {'description' => 'Disk',
                         'chart' => {'min'=>0,'unit'=> '%'},
                         'cmd' => 'check_disk_use!/',
                         'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                         'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                        'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                         :thresholds => {
                             'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                             'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                         },
             },
             'mem' =>  { 'description' => 'Memory',
                         'chart' => {'min'=>0,'unit'=>'KB'},
                         'cmd' => 'check_local_mem!90!95',
                         'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
                         'metrics' =>  {
                             'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                             'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                             'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                             'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
                         },
                         :thresholds => {
                         },
             },
             'network' => {:description => 'Network',
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
        "relations": [
          { "returnObject": false,
            "returnRelation": false,
            "relationName": "manifest.Requires",
            "direction": "to",
            "targetClassName": "manifest.Platform",
            "relations": [
              { "returnObject": false,
                "returnRelation": false,
                "relationName": "manifest.LinksTo",
                "direction": "from",
                "targetClassName": "manifest.Platform",
                "relations": [
                  { "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.Entrypoint",
                    "direction": "from"
                  }
                ]
              }
            ]
          }
        ]
      }'}}

resource 'master-user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '0..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/home/app',
             'system_account' => true,
             'sudoer' => true
         }

# overwrite volume and filesystem from generic_ring with new mount point
resource 'master-volume',
         :cookbook => "oneops.1.volume",
         :requires => {'constraint' => '0..1', 'services' => 'compute'},
         :attributes => {'mount_point' => '/data',
                         'size' => '100%FREE',
                         'device' => '',
                         'fstype' => 'ext4',
                         'options' => ''
         }

resource "master-java",
         :cookbook => "oneops.1.java",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :help => "java programming language environment"
         },
         :attributes => {

         }

resource 'master-elasticsearch',
         :cookbook => 'oneops.1.es',
         :design => true,
         :requires => {'constraint' => '0..1', 'services' => 'mirror' ,
                       "help" => " This deploys elastic search with just master responsibility and no data responsibility. Install master-java,master-volume,master-user-app,master-hostname,master-compute also when you install this."},
         :attributes => {
             'version' => '1.1.1',
             'data' => 'false',
             'master' => 'true'
         },
         :monitors => {
             'Log' => {:description => 'Log',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_logfiles!logelasticsearch!:::node.workorder.rfcCi.ciAttributes.log_dir:::/:::node.workorder.rfcCi.ciAttributes.cluster_name:::.log!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                       :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                       :cmd_options => {
                           'warningpattern' => 'WARNING',
                           'criticalpattern' => 'CRITICAL'
                       },
                       :metrics => {
                           'logelasticsearch_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                           'logelasticsearch_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                           'logelasticsearch_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                           'logelasticsearch_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                       },
                       :thresholds => {
                           'CriticalLogException' => threshold('1m', 'avg', 'logelasticsearch_criticals', trigger('>=', 1, 5, 1), reset('<', 1, 15, 1)),
                       }
             },
             'ElasticSearchStats' => {
                 :description => 'elasticsearch_stats',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_es_node_stats!:::node.workorder.rfcCi.ciAttributes.http_port:::',
                 :cmd_line => '/opt/nagios/libexec/check_es_node_stats.rb $ARG1$',
                 :metrics => {
                     'status' => metric(:unit => '',:description => 'status',:dstype => 'GAUGE',:display_group => "Process Status"),
                     'indexed_doc_count' => metric(:unit => '', :description => 'doc_count', :dstype => 'DERIVE',:display_group => "Index"),
                     'search_rate' => metric(:unit => '', :description => 'search_rate', :dstype => 'GAUGE',:display_group => "Search"),
                     'filter_cache_evictions' => metric(:unit => '', :description => 'filter_cache_evictions', :dstype => 'GAUGE',:display_group => "Cache"),
                     'heap_used_percent' => metric(:unit => '%', :description => 'Heap used percent', :dstype => 'GAUGE',:display_group => "Jvm_Stats"),
                     'gc_old_collections' => metric(:unit => '', :description => 'gc_old_collections', :dstype => 'GUAGE',:display_group => "Jvm_Stats"),
                     'index_rejections' => metric(:unit => '', :description => 'index_rejections', :dstype => 'GAUGE',:display_group => "Index"),
                     'search_rejections' => metric(:unit => '', :description => 'search_rejections', :dstype => 'GAUGE',:display_group => "Search"),
                     'disk_reads' => metric(:unit => '', :description => 'disk_reads', :dstype => 'GAUGE',:display_group => "Disk"),
                     'disk_writes' => metric(:unit => '', :description => 'disk_writes', :dstype => 'GAUGE',:display_group => "Disk"),

                 },
                 :thresholds => {
                 }
             }
         }




resource "master-hostname",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :services => "dns",
             :help => "optional hostname dns entry"
         }

#Adding a master-lb component
resource "master-lb",
         :except => [ 'single' ],
         :design => true,
         :cookbook => "oneops.1.lb",
         :requires => { "constraint" => "0..1", "services" => "compute,lb,dns" },
         :attributes => {
             "stickiness"    => "",
             "listeners" => '["http 9200 http 9200"]',
             "ecv_map"   => "{\"9200\":\"GET /\"}"
         },
         :payloads => {
             'primaryactiveclouds' => {
                 'description' => 'primaryactiveclouds',
                 'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Lb",
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
                     "targetClassName": "cloud.service.oneops.1.Netscaler"
                   }
                 ]
               }
             ]
           }
         ]
      }'
             }
         }

# depends_on
[
    {:from => 'master-os',            :to => 'master-compute' },
    {:from => 'master-hostname',      :to => 'master-os' },
    {:from => 'master-volume',        :to => 'master-os' },
    {:from => 'master-java',          :to => 'master-os'},
    {:from => 'master-user-app',      :to => 'master-os'},
    {:from => 'master-elasticsearch', :to => 'master-hostname'},
    {:from => 'master-elasticsearch', :to => 'master-volume'},
    {:from => 'master-elasticsearch', :to => 'master-java'  }
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

[ 'master-lb' ].each do |from|
  relation "#{from}::depends_on::master-compute",
           :only => [ 'redundant' ],
           :relation_name => 'DependsOn',
           :from_resource => from,
           :to_resource   => 'master-compute',
           :attributes    => { "propagate_to" => 'both', "flex" => true, "current" =>2, "min" => 2, "max" => 11 }
end

# propagation rule for replace
[ 'master-hostname' ].each do |from|
  relation "#{from}::depends_on::master-compute",
           :relation_name => 'DependsOn',
           :from_resource => from,
           :to_resource   => 'master-compute',
           :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
['master-os','master-user-app','master-volume', 'master-elasticsearch','master-java'].each do |from|
  relation "#{from}::managed_via::master-compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'master-compute',
           :attributes => {}
end

# secured_by
[ 'master-compute'].each do |from|
  relation "#{from}::secured_by::sshkeys",
           :except => [ '_default' ],
           :relation_name => 'SecuredBy',
           :from_resource => from,
           :to_resource   => 'sshkeys',
           :attributes    => { }
end

# depends_on
[ { :from => 'master-compute', :to => 'secgroup' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource   => link[:to],
           :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end
