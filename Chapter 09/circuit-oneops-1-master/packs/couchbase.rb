include_pack 'generic_ring'

name         'couchbase'
description  'CouchBase'
type         'Platform'
category     'Database NoSQL'

platform :attributes => {'autoreplace' => 'false'}

# Overriding the default compute
resource 'compute',
         :cookbook => 'oneops.1.compute',
         :attributes => {'ostype' => 'default-cloud',
                         'size' => 'S'
         }

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true
         }

resource 'couchbase',
         :cookbook => 'oneops.1.couchbase',
         :design => true,
         :requires => {'constraint' => '1..1', 'services' => 'compute,mirror'},
         :attributes => {
             'version' => 'community_3.0.1',
             'port' => '8091',
             'checksum' => '',
             'arch' => 'x86_64',
             'datapath' => '/opt/couchbase/data/',
             'pernoderamquotamb' => '80%',
             'saslpassword' => 'saslpassword',
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
             'cb_cmp' => {
             'description' => 'Get Computes for Couchbase',
             'definition' => '{
                "returnObject": false, 
                "returnRelation": false, 
                "relationName": "bom.DependsOn", 
                "direction": "to", 
                "targetClassName": "bom.oneops.1.Ring",
                "relations": [ 
                  { "returnObject": false, 
                    "returnRelation": false, 
                    "relationName": "bom.DependsOn", 
                    "direction": "from",
                    "targetClassName": "bom.oneops.1.Couchbase",
                    "relations": [ 
                      {"returnObject": true, 
                       "returnRelation": false, 
                       "relationName": "bom.DependsOn", 
                       "direction": "from",
                       "targetClassName": "bom.oneops.1.Compute"
                      }
                    ]
                  } 
                 ] 
              }'
          }
         }

resource 'bucket',
         :cookbook => 'oneops.1.bucket',
         :design => true,
         :requires => {'constraint' => '1..5'},
         :attributes => {
             'bucketname' => 'test',
             'bucketpassword' => 'password',
             'bucketmemory' => '100',
             'bucketreplica' => '1',
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
              'cb' => {
              'description' => 'Bucket',
              'definition' => '{
                 "returnObject": false, 
                 "returnRelation": false, 
                 "relationName": "bom.DependsOn", 
                 "direction": "from", 
                 "targetClassName": "bom.oneops.1.Ring",
                 "relations": [ 
                   { "returnObject": true, 
                     "returnRelation": false, 
                     "relationName": "bom.DependsOn", 
                     "direction": "from",
                     "targetClassName": "bom.oneops.1.Couchbase"
                     
                   } 
                  ] 
               }'
             }
            }

resource 'couchbase-cluster',
         :cookbook => 'oneops.1.cb_cluster',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'bucketname' => 'test',
             'bucketpassword' => 'password',
             'bucketmemory' => '100',
             'bucketreplica' => '1',
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
             'cm' => {
                 'description' => 'Couchbase Cluster Manager',
                 'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Ring",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "from",
                     "targetClassName": "bom.oneops.1.Couchbase"

                   }
                  ]
               }'
             },
             'cb_buckets' => {
                 'description' => 'Buckets',
                 'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Ring",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "to",
                     "targetClassName": "bom.oneops.1.Bucket"
             }
                  ]
               }'
             }

         }

resource 'diagnostic-cache',
         :cookbook => 'oneops.1.diagnostic_cache',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'Disgnotic-Cache',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true,
             'adminuser' => 'Administrator',
             'adminpassword' => 'password'
         },
         :payloads => {
             'dc' => {
                 'description' => 'Diagnostic',
                 'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Compute",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "to",
                     "targetClassName": "bom.oneops.1.Couchbase"
                   }
                  ]
               }'
             },
             'cb_cmp' => {
                 'description' => 'Get Computes for Couchbase',
                 'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Compute",
                 "relations": [
                   { "returnObject": false,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "to",
                     "targetClassName": "bom.oneops.1.Couchbase",
                     "relations": [ 
                       { "returnObject": false, 
                         "returnRelation": false, 
                         "relationName": "bom.DependsOn", 
                         "direction": "to", 
                         "targetClassName": "bom.oneops.1.Ring", 
                         "relations": [ 
                           { "returnObject": false, 
                             "returnRelation": false, 
                             "relationName": "bom.DependsOn", 
                             "direction": "from",
                             "targetClassName": "bom.oneops.1.Couchbase",
                             "relations": [ 
                               { "returnObject": true, 
                                 "returnRelation": false, 
                                 "relationName": "bom.DependsOn", 
                                 "direction": "from",
                                 "targetClassName": "bom.oneops.1.Couchbase"
                               }
                             ]
                           } 
                         ]
                       }
                     ]
                    }
                  ]
                 }'
             }
         },
         :monitors => {
             'client-interface-port' => {
                 :description => 'Client Interface Port',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_client_interface!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:critical]}!#{cmd_options[:wait]}',
                 :cmd_line => '/opt/nagios/libexec/check_port.pl  -h $ARG1$ -p $ARG2$ -c $ARG3$ -w $ARG4$ -v',
                 :cmd_options => {
                     'host' => 'localhost',
                     'port' => '11211',
                     'critical' => '1.0',
                     'wait' => '0.5'
                 },
                 :metrics => {
                     'port_open' => metric(:unit => '', :description => 'Port Open', :dstype => 'GAUGE'),
                     'rta' => metric(:unit => '', :description => 'Response Time Avg', :dstype => 'GAUGE'),
                     'critical_response' => metric(:unit => '', :description => 'Critical Response Time', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                     'CriticalExceptions' => threshold('1m', 'avg', 'critical_response', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1)),
                 }

             },
             'internal-cluster-port' => {
                 :description => 'Internal Cluster Port',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_client_interface!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:critical]}!#{cmd_options[:wait]}',
                 :cmd_line => '/opt/nagios/libexec/check_port.pl  -h $ARG1$ -p $ARG2$ -c $ARG3$ -w $ARG4$ -v',
                 :cmd_options => {
                     'host' => 'localhost',
                     'port' => '11210',
                     'critical' => '1.0',
                     'wait' => '0.5'
                 },
                 :metrics => {
                     'port_open' => metric(:unit => '', :description => 'Port Open', :dstype => 'GAUGE'),
                     'rta' => metric(:unit => '', :description => 'Response Time Avg', :dstype => 'GAUGE'),
                     'critical_response' => metric(:unit => '', :description => 'Critical Response Time', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                     'CriticalExceptions' => threshold('1m', 'avg', 'critical_response', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1)),
                 }

             },
             'cb-admin-console' => {
                 :description => 'Couchbase Admin Console',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_admin_console!#{cmd_options[:host]}!#{cmd_options[:port]}!:::node.workorder.rfcCi.ciAttributes.adminuser:::!:::node.workorder.rfcCi.ciAttributes.adminpassword:::!#{cmd_options[:wait]}!#{cmd_options[:critical]}',
                 :cmd_line => '/opt/nagios/libexec/check_http_admin_console.sh $ARG1$ $ARG2$ /pools $ARG3$ $ARG4$ $ARG6$  $ARG5$  "HTTP/1.1 200"',
                 :cmd_options => {
                     'host' => 'localhost',
                     'port' => '8091',
                     'critical' => '10',
                     'wait' => '5.0',
                 },
                 :metrics =>  {
                     'time'   => metric( :unit => '', :description => 'Response Time', :dstype => 'GAUGE'),
                     'size'   => metric( :unit => '', :description => 'Size', :dstype => 'GAUGE', :display => false),
                     'critical_response' => metric(:unit => '', :description => 'Critical Response Time', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                     'TimeExceptions' => threshold('1m', 'avg', 'time', trigger('>=', 6, 10, 1), reset('<', 6, 1, 1)),
                     'CriticalExceptions' => threshold('1m', 'avg', 'critical_response', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1)),
                 }
             },
             'cluster-cluster' => {
                 :description => 'Cluster Health Info',
                 :source => '',
                 :chart => {'min'=>0, 'unit'=>''},
                 :cmd => 'check_cluster_health!:::node.workorder.rfcCi.ciAttributes.adminuser:::!:::node.workorder.rfcCi.ciAttributes.adminpassword:::',
                 :cmd_line => '/opt/nagios/libexec/check_cluster_health.rb  -U $ARG1$ -P $ARG2$',
                 :metrics => {
                     'cluster_node_size' => metric(:unit => '', :description => 'cluster_node_size', :dstype => 'GAUGE', :display_group => "Cluster Node Size"),
                     
                     'rebalance' => metric(:unit => '', :description => 'Rebalance Running Status', :dstype => 'GAUGE', :display_group => "Rebalance"),
                     'rebalance_failed' => metric(:unit => '', :description => 'Rebalance Failed', :dstype => 'GAUGE', :display_group => "Rebalance"),
                     
                     'unhealthy_node_status' => metric(:unit => '', :description => 'Unhealthy Node Status', :dstype => 'GAUGE', :display_group => "Node Issues"),
                     'unhealthy_node_cluster_membership' => metric(:unit => '', :description => 'Unhealthy Node Cluster Membership', :dstype => 'GAUGE', :display_group => "Node Issues"),
                     'unable_to_connect_to_node' => metric(:unit => '', :description => 'Unable To Connect To Node', :dstype => 'GAUGE', :display_group => "Node Issues"),
                     
                     'writing_data_to_disk_failed' => metric(:unit => '%', :description => 'Writing data to disk for a specific bucket has failed', :dstype => 'GAUGE', :display_group => "Write Failed"),
                     
                     'metadata_overhead' => metric(:unit => '%', :description => 'Metadata Overhead', :dstype => 'GAUGE', :display_group => "Metadata Overhead"),
                     
                     'disk_space_used' => metric(:unit => '%', :description => 'Disk Space Used', :dstype => 'GAUGE', :display_group => "Disk Space"),
                     
                     'cache_miss_ratio' => metric(:unit => '%', :description => 'Cache Miss Ratio', :dstype => 'GAUGE', :display_group => "Cache Miss"),
                     
                     'disk_write_queue' => metric(:unit => '', :description => 'Disk Write Queue', :dstype => 'GAUGE', :display_group => "Disk Performance"),
                     'disk_read_per_sec' => metric(:unit => '', :description => 'Disk Read per Second', :dstype => 'GAUGE', :display_group => "Disk Performance"),
                     
                     'replica_ejection_per_sec' => metric(:unit => '', :description => 'Replica Ejection per Second', :dstype => 'GAUGE', :display_group => "Ejection"),
                     'active_ejection_per_sec' => metric(:unit => '', :description => 'Active Ejection per Second', :dstype => 'GAUGE', :display_group => "Ejection"),
                     
                     'temp_oom_per_sec' => metric(:unit => '', :description => 'Temp OOM per second', :dstype => 'GAUGE', :display_group => "OOM"),
                     
                     'replica_doc_resident' => metric(:unit => '%', :description => 'Replica resident % - Percentage of replicas in RAM.', :dstype => 'GAUGE', :display_group => "Doc Resident"),
                     'active_doc_resident' => metric(:unit => '%', :description => 'Active docs resident % - Percentage of docs in RAM', :dstype => 'GAUGE', :display_group => "Doc Resident")
                     
                 },
                 :thresholds => {
                     'UnhealthyNodeStatusExceptions' => threshold('1m', 'avg', 'unhealthy_node_status', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1), 'unhealthy'),
                     'NodeConnectExceptions' => threshold('1m', 'avg', 'unable_to_connect_to_node', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1), 'unhealthy'),
                     'UnhealthyNodeClusterMembershipExceptions' => threshold('1m', 'avg', 'unhealthy_node_cluster_membership', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1), 'unhealthy'),
                     
                     'WritingDataToDiskFailedExceptions' => threshold('1m', 'avg', 'writing_data_to_disk_failed', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1)),
                     
                     'MetadataOverheadOneHundredExceptions' => threshold('1m', 'avg', 'metadata_overhead', trigger('>=', 100, 5, 1), reset('<', 100, 5, 1)),
                     'MetadataOverheadFiftyExceptions' => threshold('1m', 'avg', 'metadata_overhead', trigger('>=', 50, 5, 1), reset('<', 50, 5, 1)),
                     
                     'DiskSpaceExceptions' => threshold('1m', 'avg', 'disk_space_used', trigger('>=', 90, 5, 1), reset('<', 90, 5, 1)),
                     
                     'HighCacheMissRatio' => threshold('5m', 'avg', 'cache_miss_ratio', trigger('>', 50, 5, 1), reset('<', 50, 5, 1)),
                     
                     'HighDiskWriteQueue' => threshold('5m', 'avg', 'disk_write_queue', trigger('>', 1000, 5, 1), reset('<', 1000, 5, 1)),
                     'HighDiskRead' => threshold('5m', 'avg', 'disk_read_per_sec', trigger('>', 10, 5, 1), reset('<', 10, 5, 1)),
                     
                     'HighReplicaEjection' => threshold('5m', 'avg', 'replica_ejection_per_sec', trigger('>', 1, 5, 1), reset('<', 1, 5, 1)),
                     'HighActiveEjection' => threshold('5m', 'avg', 'active_ejection_per_sec', trigger('>', 1, 5, 1), reset('<', 1, 5, 1)),
                     
                     'HighTempOOM' => threshold('5m', 'avg', 'temp_oom_per_sec', trigger('>', 3, 5, 1), reset('<', 3, 5, 1)),
                     
                     'HighReplicaDocResident' => threshold('5m', 'avg', 'replica_doc_resident', trigger('<', 100, 5, 1), reset('=', 100, 5, 1)),
                     'HighActiveDocResident' => threshold('5m', 'avg', 'active_doc_resident', trigger('<', 100, 5, 1), reset('=', 100, 5, 1))
                     
                 }
                 
             },
             'shared_hypervisor_count' => {
                 :description => 'Shared Hypervisor Count',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_shared_hypervisor!',
                 :cmd_line => '/opt/nagios/libexec/check_shared_hypervisor.rb',
                 :metrics => {
                     'shared_hypervisor_count' => metric(:unit => '', :description => 'Shared Hypervisor Count - The number of other Couchbase nodes in this cluster sharing this hypervisor', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                     'SharedHypervisorCount' => threshold('5m', 'avg', 'shared_hypervisor_count', trigger('>=', 1, 5, 1), reset('<', 1, 5, 1))
                 }
             }
         }

# overwrite volume and filesystem from generic_ring with new mount point
resource 'volume',
         :requires => {'constraint' => '1..1', 'services' => 'compute'},
         :attributes => {'mount_point' => '/opt/couchbase',
                         'size' => '100%FREE',
                         'device' => '',
                         'fstype' => 'ext4',
                         'options' => ''
         }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "4369 4369 tcp 0.0.0.0/0", "8091 8092 tcp 0.0.0.0/0", "18091 18092 tcp 0.0.0.0/0", "11214 11215 tcp 0.0.0.0/0", "11209 11211 tcp 0.0.0.0/0", "21100 21299 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

# depends_on
[{:from => 'user-app',  :to => 'compute'},
 {:from => 'diagnostic-cache',  :to => 'compute'},
 {:from => 'diagnostic-cache', :to => 'user-app'},
 {:from => 'couchbase', :to => 'user-app'},
 {:from => 'couchbase', :to => 'compute'},
 {:from => 'couchbase', :to => 'volume'},
 {:from => 'build', :to => 'couchbase'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "ring::depends_on::couchbase",
         :except => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'ring',
         :to_resource => 'couchbase',
         :attributes => {"flex" => true, "min" => 3, "max" => 10}

relation "couchbase-cluster::depends_on::ring",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'couchbase-cluster',
         :to_resource   => 'ring',
         :attributes    => {"flex" => false}

relation "couchbase-cluster::depends_on::couchbase",
         :only => [ '_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'couchbase-cluster',
         :to_resource   => 'couchbase',
         :attributes    =>{"flex" => false}

relation "bucket::depends_on::ring",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'bucket',
         :to_resource   => 'ring',
         :attributes    => {"flex" => false}

relation "bucket::depends_on::couchbase",
         :only => [ '_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'bucket',
         :to_resource   => 'couchbase',
         :attributes    =>{"flex" => false}

# managed_via
['user-app', 'diagnostic-cache', 'couchbase', 'bucket', 'couchbase-cluster', 'build'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end

# SecuredBy
['couchbase-cluster'].each do |from|
  relation "#{from}::secured_by::sshkeys",
           :except => [ '_default'],
           :relation_name => 'SecuredBy',
           :from_resource => from,
           :to_resource   => 'sshkeys',
           :attributes    => { }
end
