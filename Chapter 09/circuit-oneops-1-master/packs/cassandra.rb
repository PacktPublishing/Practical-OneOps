include_pack "generic_ring"

name "cassandra"
description "Cassandra"
type "Platform"
category "Database NoSQL"

platform :attributes => {'autoreplace' => 'false'}

resource "cassandra",
  :cookbook => "oneops.1.cassandra",
  :design => true,
  :requires => {
      :constraint => "1..1",
      :services => "mirror",
      :help => 'Cassandra Server'
    },
  :attributes => {
    "version"       => "2.1.9",
    "cluster"       => "TestCluster",
    "config_directives" => '{
      "data_file_directories":"/var/lib/cassandra/data",
      "saved_caches_directory":"/var/lib/cassandra/saved_caches",
      "commitlog_directory":"/var/lib/cassandra/commitlog"
    }',
    "log4j_directives" => '{
      "log4j.appender.R.File":"/var/log/cassandra/system.log",
      "log4j.appender.R.maxFileSize":"10MB",
      "log4j.rootLogger":"INFO,stdout,R"
    }'
  },
  :monitors => {
       'Log' => {:description => 'Log',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logcassandra!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/var/log/cassandra/system.log',
                     'warningpattern' => 'ERROR',
                     'criticalpattern' => 'CRITICAL'
                 },
                 :metrics => {
                     'logcassandra_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logcassandra_errors' => metric(:unit => 'errors', :description => 'Errors', :dstype => 'GAUGE'),
                     'logcassandra_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logcassandra_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                   'CriticalLogException' => threshold('1m', 'avg', 'criticals', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1)),
                 }
       },
      'ReadOperations' =>  { :description => 'Read Operations',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Per Second'},
                  :cmd => 'check_cassandra_reads',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.db:type=StorageProxy '+
                               '-A ReadOperations',
                  :metrics =>  {
                    'ReadOperations'   => metric( :unit => 'per second', :description => 'Read Operations', :dstype => 'DERIVE'),
                  },
                  :thresholds => {
                  }
                },
      'WriteOperations' =>  { :description => 'Write Operations',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Per Second'},
                  :cmd => 'check_cassandra_writes',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.db:type=StorageProxy '+
                               '-A WriteOperations',
                  :metrics =>  {
                    'WriteOperations'   => metric( :unit => 'Per Second', :description => 'Write Operations', :dstype => 'DERIVE'),
                  },
                  :thresholds => {
                  }
                }
  },
  :payloads => {
'clouds' => {
    'description' => 'clouds',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Cassandra",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "from",
           "targetClassName": "manifest.oneops.1.Compute",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute",
               "relations": [
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.DeployedTo",
                   "direction": "from",
                   "targetClassName": "account.Cloud"
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
'computes' => {
    'description' => 'computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Cassandra",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "from",
           "targetClassName": "manifest.oneops.1.Compute",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute"
             }
           ]
         }
       ]
    }'
  }
 }



# overwrite volume from generic_ring to make them mandatory
resource "volume",
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/var/lib/cassandra',
                    "device"        => '',
                    "fstype"        => 'xfs',
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
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',45,5,1),reset('<',45,5,1))
                  },
                },
    }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => {
             :constraint => "0..*"
         }

resource "keyspace",
         :cookbook => "oneops.1.keyspace",
         :design => true,
         :requires => {"constraint" => "0..*"},
         :attributes => {
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '0..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "1024 65535 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
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
             },
             'LogstashMetrics' =>  { :description => 'LogstashMetrics',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Per Second'},
                  :charts => [
                    {'min'=>0, 'unit'=>'Current Count', 'metrics'=>["eps", "connections","connections_backlogged"]}
                  ],
                  :cmd => 'check_logstash',
                  :cmd_line => '/opt/nagios/libexec/check_logstash',
                  :metrics =>  {
                    'eps'   => metric( :unit => 'count', :description => 'Events Processed Per Second', :dstype => 'GAUGE'),
                    'connections'   => metric( :unit => 'count', :description => 'Connections', :dstype => 'GAUGE'),
                    'connections_backlogged'   => metric( :unit => 'count', :description => 'Connections with Backlog', :dstype => 'GAUGE')
                  },
                  :thresholds => {
                  }
                }
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
[ { :from => 'java',      :to => 'os' },
  { :from => 'haproxy',   :to => 'os' },
  { :from => 'cassandra', :to => 'volume' },
  { :from => 'cassandra', :to => 'share' },
  { :from => 'cassandra', :to => 'hostname' },
  { :from => 'cassandra', :to => 'java' },
  { :from => 'daemon',    :to => 'cassandra'  },
  { :from => 'artifact',  :to => 'cassandra'  },
  { :from => 'logstash',  :to => 'artifact'  },
  { :from => 'daemon',    :to => 'artifact'  },
  { :from => 'build',     :to => 'cassandra'  }  ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end


[{ :from => 'cassandra', :to => 'compute' }].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => {"propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

relation "ring::depends_on::cassandra",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'cassandra',
    :attributes    => { "flex" => true, "min" => 3, "max" => 10 }

relation "keyspace::depends_on::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'keyspace',
    :to_resource   => 'ring',
    :attributes    => { }

relation "keyspace::depends_on::cassandra",
    :except => [ 'redundant' ],
    :relation_name => 'DependsOn',
    :from_resource => 'keyspace',
    :to_resource   => 'cassandra',
    :attributes    => { }

# managed_via
[ 'cassandra','java','artifact', 'logstash','haproxy'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

[ 'keyspace'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default', 'redundant' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

[ 'keyspace'].each do |from|
  relation "#{from}::managed_via::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'ring',
    :attributes    => { }
end

procedure "nodetool",
  :description => "Cassandra nodetool",
  :arguments => {
        "nodetool arguments" => {
                "name" => "nodetool_args",
                "defaultValue" => "status",
                "dataType" => "string"
        }
   },
   :definition => '{
    "flow": [
        {
            "execStrategy": "one-by-one",
            "relationName": "manifest.Requires",
            "direction": "from",
            "targetClassName": "manifest.oneops.1.Cassandra",
            "flow": [
                {
                    "relationName": "base.RealizedAs",
                    "execStrategy": "one-by-one",
                    "direction": "from",
                    "targetClassName": "bom.oneops.1.Cassandra",
                    "actions": [
                        {
                            "actionName": "nodetool",
                            "stepNumber": 1,
                            "isCritical": true
                        }
                    ]
                }
            ]
        }
    ]
}'