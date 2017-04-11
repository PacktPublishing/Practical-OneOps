name             "Cassandra"
description      "Installs/Configures Cassandra"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest']

grouping 'bom',
         :access => "global",
         :packages => ['bom']


attribute 'version',
          :description => "Version",
          :required => "required",
          :default => "2.2.4",
          :format => {
              :important => true,
              :tip => 'Supported versions are 1.2.x .. 2.2.x',
              :help => 'Version of Cassandra',
              :category => '1.Global',
              :order => 1
          }

attribute 'cluster',
          :description => "Cluster Name",
          :required => "required",
          :default => "TestCluster",
          :format => {
              :help => 'Name of the cluster',
              :category => '1.Global',
              :order => 2
          }


attribute 'num_tokens',
          :description => "Vnode num_tokens",
          :required => "required",
          :default => "256",
          :format => {
              :help => 'Vnode num_tokens',
              :category => '1.Global',
              :order => 3
          }


attribute 'partitioner',
          :description => "Partitioner",
          :default => "org.apache.cassandra.dht.Murmur3Partitioner",
          :format => {
              :important => true,
              :help => 'Partitioner',
              :category => '1.Global',
              :order => 4
          }

attribute 'auth_enabled',
          :description => 'Authentication',
          :default => 'false',
          :format => {
            :help => 'Authentication enabled',
            :category => '1.Global',
            :order => 5,
            :form => { 'field' => 'checkbox' }
          }

attribute 'endpoint_snitch',
          :description => "Endpoint Snitch",
          :required => "required",
          :default => "org.apache.cassandra.locator.GossipingPropertyFileSnitch",
          :format => {
              :important => true,
              :help => 'Sets the snitch to use for locating nodes and routing requests. In deployments with rack-aware replication placement strategies, use either RackInferringSnitch, PropertyFileSnitch, or EC2Snitch (if on Amazon EC2). Has a dependency on the replica placement_strategy, which is defined on a keyspace. The PropertyFileSnitch also requires a cassandra-topology.properties configuration file. ',
              :category => '2.Topology',
              :order => 1,
              :form => {'field' => 'select', 
                        'options_for_select' => [
                                                  ['GossipingPropertyFileSnitch', 'org.apache.cassandra.locator.GossipingPropertyFileSnitch'],
                                                  ['PropertyFileSnitch', 'org.apache.cassandra.locator.PropertyFileSnitch'],
                                                  ['RackInferringSnitch', 'org.apache.cassandra.locator.RackInferringSnitch']
                                                ]
                       }
          }

attribute 'cloud_dc_rack_map',
          :description => "Map of Cloud to DC:Rack",
          :default => "{}",
          :required => "required",
          :data_type => "hash",
          :format => {
              :help => 'Map of Cloud to DC:Rack for PropertyFileSnitch generates base cassandra-topology.properties',
              :category => '2.Topology',
              :order => 2,
              :filter => {"all" => {"visible" => ('endpoint_snitch:eq:org.apache.cassandra.locator.PropertyFileSnitch || endpoint_snitch:eq:org.apache.cassandra.locator.GossipingPropertyFileSnitch')}}
          }

attribute 'extra_topology',
          :description => "Extra Topolgy",
          :default => "",
          :data_type => "text",
          :format => {
              :help => 'Additional content added to cassandra-topology.properties',
              :category => '2.Topology',
              :order => 3,
              :filter => {"all" => {"visible" => ('endpoint_snitch:eq:org.apache.cassandra.locator.PropertyFileSnitch || endpoint_snitch:eq:org.apache.cassandra.locator.GossipingPropertyFileSnitch')}}
          }

attribute 'node_ip',
          :description => "Node IP",
          :default => "",
          :grouping => "bom",
          :data_type => "text",
          :format => {
              :help => 'Node IP (used during replace)',
              :category => '2.Topology',
              :order => 4
          }
          
attribute 'seeds',
          :description => "Seeds",
          :default => '[]',
          :data_type => 'array',
          :format => {
              :help => 'Seeds - if empty values will be generated based on seed_count attr',
              :category => '2.Topology',
              :order => 5
          }          

attribute 'seed_count',
          :description => "seed_count",
          :default => "1",
          :format => {
              :help => 'if seed_count changes will generate new seed list based on hostnames',
              :category => '2.Topology',
              :order => 6
          }          


attribute 'config_directives',
          :description => 'Cassandra Options',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Overrides config/cassandra.yaml entries. Nested config values like list and mappings can be expressed as JSON (Eg: [],{} etc). Applicable with all versions of Cassandra 1.2 and later. Eg: rpc_server_type = hsha',
              :category => '3.Configuration Directives',
              :order => 1
          }

attribute 'jvm_opts',
          :description => 'JVM Options',
          :default => '[]',
          :data_type => 'array',
          :format => {
              :help => 'array of JVM_OPTS for cassandra-env.sh',
              :category => '3.Configuration Directives',
              :order => 2
          }

attribute 'log4j_directives',
          :description => 'Log4j Options',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Overrides config/log4j-server.properties or logback.xml entries. Eg: log4j.appender.R.maxFileSize = 20MB',
              :category => '3.Configuration Directives',
              :order => 3
          }
          
attribute 'install_dir',
          :description => "Installation Directory",
          :default => "/opt",
          :format => {
              :help => 'Binary will be installed here (ex. /opt)',
              :category => '3.Configuration Directives',
              :order => 4
          }

attribute 'heap_newsize',
          :description => "Young generation heap size",
          :required => "required",
          :default => "default",
          :format => {
              :help => 'Set custom -Xmn : size of the heap for the young generation. Example value: 100M',
              :category => '4.Memory',
              :order => 1
          }

attribute 'max_heap_size',
          :description => "Max and Inital Heap Size",
          :required => "required",
          :default => "default",
          :format => {
              :important => true,
              :help => 'Set custom -Xmx -Xms size - same value: to avoid stop-the-world GC pauses during resize, and so that we can lock the heap in memory on startup to prevent any of it from being swapped out. Example value: 256M',
              :category => '4.Memory',
              :order => 2
          }



attribute 'mirrors',
          :description => "Binary distribution mirrors",
          :required => "required",
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '5.Mirror',
              :help => 'Apache distribution compliant mirrors - uri without /tomcat/tomcat-x/... path',
              :order => 1
          }

attribute 'checksum',
          :description => "Binary distribution checksum",
          :format => {
              :category => '5.Mirror',
              :help => 'md5 checksum of the file',
              :order => 2
          }


attribute 'incremental_backups',
          :description => "Enable Incremental Backups",
          :default => 'false',
          :format => {
              :help => 'Enable Incremental Backups',
              :category => '6.Backups',
              :form => {'field' => 'checkbox'},
              :order => 1
          }

recipe "status", "Cassandra Status"
recipe "start", "Start Cassandra"
recipe "stop", "Stop Cassandra"
recipe "restart", "Restart Cassandra"
recipe "stopdrain", "Stop Cassandra (with drain)"
recipe "restartdrain", "Restart Cassandra (with drain)"
recipe "repair", "Repair Cassandra"
recipe "nodetoolrepairpr", "Repair PrimaryRange data"
recipe "compactionstats", "Compaction Stats"
recipe "netstats", "Net Stats"
recipe "ringstatus", "Ring Status"
recipe "nodetool",
      :description => "Submit custom nodetool parameter",
      :args => {
        "nodetool_args" => {
        "name" => "nodetool_args",
        "description" => "nodetool command",
        "defaultValue" => "status",
        "required" => true,
        "dataType" => "string"
        }
      }
