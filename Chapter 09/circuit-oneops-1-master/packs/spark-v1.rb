include_pack "base"

name "spark-v1"
description "Apache Spark (V1 Build)"
type "Platform"
category "Spark"

# Versioning attributes
spark_version = "1"
spark_cookbook = "oneops.1.spark-v#{spark_version}"
# When changing version, need to change the class name in payload definitions.

platform :attributes => {'autoreplace' => 'false'}

# Define resources for spark workers
resource 'secgroup',
         :cookbook   => 'oneops.1.secgroup',
         :design     => true,
         :attributes => {
           # Port configuration:
           #
           #  null:  Ping
           #    22:  SSH
           #  4040-
           #  4049:  Spark Application UI
           #  7077:  Spark master
           #  8080:  Spark master UI
           #  8081:  Spark worker UI
           #  9000:  Spark worker
           # 10000:  Spark Thrift Server
           # 18080:  Spark History Server UI
           # 60000:  For mosh
           #
           "inbound" => '[
               "null null 4 0.0.0.0/0",
               "22 22 tcp 0.0.0.0/0",
               "4040 4049 tcp 0.0.0.0/0",
               "7077 7077 tcp 0.0.0.0/0",
               "8080 8081 tcp 0.0.0.0/0",
               "9000 9000 tcp 0.0.0.0/0",
               "10000 10000 tcp 0.0.0.0/0",
               "18080 18080 tcp 0.0.0.0/0",
               "60000 60100 udp 0.0.0.0/0"
           ]'
         },
         :requires   => {
           :constraint => '1..1',
           :services   => 'compute'
         }

resource 'spark-cluster',
         :except   => ['single'],
         :cookbook => 'oneops.1.spark-cluster-v1',
         :design   => false,
         :requires => {:constraint => '1..1'},
         :payloads => {
           # clusterSparkMasters - The compute instances for all computes in
           #                       the deployment that are Spark masters
           #                       Path: Cluster definition (starting point)
           #                             -> depends on Spark (worker configs)
           #                             -> depends on Spark (master configs)
           #                             -> depends on compute (master compute def)
           #                             -> realized as compute (compute instance)
           'clusterSparkMasters' => {
             'description' => 'Spark Master Computes',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-cluster-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Spark-v1",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.DependsOn",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Spark-v1",
                       "relations": [
                         { "returnObject": false,
                           "returnRelation": false,
                           "relationName": "manifest.DependsOn",
                           "direction": "from",
                           "targetClassName": "manifest.oneops.1.Os",
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
                         }
                       ]
                     }
                   ]
                 }
               ]
             }'
           },
           # clusterSparkWorkers - The compute instances for all computes in
           #                       the deployment that are Spark workers
           #                       Path: Cluster definition (starting point)
           #                             -> depends on Spark (worker configs)
           #                             -> depends on compute (worker compute def)
           #                             -> realized as compute (compute instance)
           'clusterSparkWorkers' => {
             'description' => 'Spark Worker Computes',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-cluster-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Spark-v1",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.DependsOn",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Os",
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
                     }
                   ]
                 }
               ]
             }'
           },
           # sparkConfig - The main Spark configuration object for
           #               the deployment
           #               Path: Cluster definition (starting point)
           #                     -> depends on Spark (worker configs)
           #                     -> depends on Spark (master configs)
           'sparkConfig' => {
             'description' => 'Spark Configuration',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-cluster-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Spark-v1",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "manifest.DependsOn",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Spark-v1"
                     }
                   ]
                 }
               ]
             }'
           },
           # clouds - All clouds included in the deployment
           #          Path: Cluster definition (starting point)
           #                -> realized as cluster implementation (all clusters)
           #                -> deployed to cloud
           'clouds' => {
             'description' => 'Clouds in Deployment',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-cluster-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedAs",
                   "direction": "from",
                   "targetClassName": "bom.oneops.1.Spark-cluster-v1",
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
             }'
           },
           # clusterSparkClients - The compute instances for the Spark
           #                       client.
           #                       Path: Cluster definition (starting point)
           #                             -> required by platform (Platform definition)
           #                             -> requires spark-client (spark-client config)
           #                             -> depends on os (os definition)
           #                             -> depends on compute (compute definition)
           #                             -> realized as compute (compute instance)
           'clusterSparkClients' => {
             'description' => 'Spark Client Computes',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-cluster-v1",
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
                       "targetCiName": "spark-client",
                       "targetClassName": "manifest.oneops.1.Spark-v1",
                       "relations": [
                         { "returnObject": false,
                           "returnRelation": false,
                           "relationName": "manifest.DependsOn",
                           "direction": "from",
                           "targetClassName": "manifest.oneops.1.Os",
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
                         }
                       ]
                     }
                   ]
                 }
               ]
             }'
           }
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
           'flavor' => 'oracle',
           'jrejdk' => 'server-jre'
         }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => { "constraint" => "0..*" },
         :attributes => {

         },
         :monitors => {
             'URL' => {:description => 'URL',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
                       :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
                       :cmd_options => {
                           'host' => 'localhost',
                           'port' => '8080',
                           'url' => '/',
                           'wait' => '15',
                           'expect' => '200 OK',
                           'regex' => ''
                       },
                       :metrics => {
                           'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
                           'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE'),
                           'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false)
                       },
                       :thresholds => {

                       }
             },
             'exceptions' => {:description => 'Exceptions',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_logfiles!logexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                              :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                              :cmd_options => {
                                  'logfile' => '/log/logmon/logmon.log',
                                  'warningpattern' => 'Exception',
                                  'criticalpattern' => 'Exception'
                              },
                              :metrics => {
                                  'logexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                                  'logexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                                  'logexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                                  'logexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                              },
                              :thresholds => {
                                  'CriticalExceptions' => threshold('15m', 'avg', 'logexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
                              }
             }
         }

resource "hadoop-yarn-config",
         :cookbook => "oneops.1.hadoop-yarn-config-v1",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "client"
         }

# For Spark workers, this is named "yarn" to prevent the recipes from
# adding the client components.
resource "yarn",
         :cookbook => "oneops.1.hadoop-yarn-v1",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "resource manager"
         },
         :payloads => {
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

resource 'spark-worker',
         :cookbook   => spark_cookbook,
#         :source => Chef::Config[:register],
# spark-worker is not present in design view since it reads all Spark settings from the Spark master component
         :design     => false,
         :attributes => {
           # No attributes are configured since Spark-worker gets all settings from the Spark master component
           "spark_custom_download" => " ",
           "spark_download_location" => "nexus"
         },
         :requires   => {
           :constraint => '1..1',
           :services => '*maven',
           :help       => 'Spark Cluster'
         },
         :monitors => {
           'CheckWorker' => {
             :description => 'Spark Worker Process',
             :source      => '',
             :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
             :cmd         => 'check_process!spark!true!none',
             :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
             :metrics     => {
               'up' => metric(:unit => '%', :description => 'Percent Up'),
             },
             :thresholds  => {
               'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
             }
           },
           'Log' => {
             :description => 'Spark Worker Log',
             :source => '',
             :chart => {'min' => 0, 'unit' => ''},
             :cmd => 'check_logfiles!logsparkworker!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
             :cmd_line => '/opt/nagios/libexec/check_spark_log.sh $ARG1$ $ARG2$ "$ARG3$" "$ARG4$"',
             :cmd_options => {
               'logfile' => 'worker',
               'warningpattern' => 'WARN',
               'criticalpattern' => 'ERROR'
             },
             :metrics => {
               'logsparkworker_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
               'logsparkworker_errors' => metric(:unit => 'errors', :description => 'Errors', :dstype => 'GAUGE'),
               'logsparkworker_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
               'logsparkworker_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
             },
             :thresholds => {
               'CriticalLogException' => threshold('1m', 'avg', 'criticals', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1),'unhealthy'),
             }
           }
         },
         :payloads => {
           # sparkMasters - The compute instances for all computes in
           #                the deployment that are Spark masters
           #                Path: Spark definition (starting point)
           #                      -> depends on Spark (master configs)
           #                      -> depends on compute (master compute def)
           #                      -> realized as compute (compute instance)
           'sparkMasters' => {
             'description' => 'Spark Master Computes',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Spark-v1",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.DependsOn",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Os",
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
                     }
                   ]
                 }
               ]
             }'
           },
           # sparkKeys - All ssh keys used in this deployment.
           #             Path: Spark definition (starting point)
           #                   -> managed via compute (compute definition)
           #                   -> realized as compute (compute instance)
           #                   -> secured by keypair (keypair definition)
           #                   -> realized as keypair (keypair instances)
           'sparkKeys' => {
             'description' => 'Spark Public keys',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "bom.ManagedVia",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedAs",
                   "direction": "to",
                   "targetClassName": "manifest.oneops.1.Compute",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.SecuredBy",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Keypair",
                       "relations": [
                         { "returnObject": true,
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

resource "hostname",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "dns",
           :help => "hostname dns entry"
         }

resource "volume-work",
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
               'chart' => {'min'=>0,'unit'=> 'Percent used'},
               'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
               'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
               'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                              'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
               :thresholds => {
                 'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                 'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
               }
             }
         }

# depends_on
[ { :from => 'volume-work', :to => 'os' },
  { :from => 'volume-work', :to => 'compute' },
  { :from => 'java', :to => 'os' },
  { :from => 'yarn', :to => 'java' },
  { :from => 'daemon',    :to => 'artifact'  }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ { :from => 'spark-worker', :to => 'os' },
  { :from => 'spark-worker', :to => 'java' },
  { :from => 'spark-worker', :to => 'volume-work' },
  { :from => 'daemon',    :to => 'spark-worker'  },
  { :from => 'artifact',  :to => 'spark-worker'  }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ { :from => 'hadoop-yarn-config', :to => 'os-master' }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# DependsOn relationships that need to have changes propagated to the
# "from" component.
[ { :from => 'spark-worker', :to => 'yarn', :converge => false },
  { :from => 'yarn-master', :to => 'hadoop-yarn-config', :converge => true },
  { :from => 'yarn', :to => 'hadoop-yarn-config', :converge => true }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => link[:converge], "min" => 1, "max" => 1 }
end

relation "spark-cluster::depends_on::spark-worker",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'spark-cluster',
    :to_resource   => 'spark-worker',
    :attributes    => { :propagate_to => 'from', "flex" => true, "min" => 1, "max" => 10 }

relation 'fqdn::depends_on::spark-cluster',
         :except        => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'spark-cluster',
         :attributes    => {:propagate_to => 'from', :flex => false, :min => 1, :max => 1}

relation 'fqdn::depends_on::compute',
         :only          => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'compute',
         :attributes    => {:flex => false, :min => 1, :max => 1}

['java','spark-worker', 'artifact', 'volume-work', 'yarn'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

relation 'spark-cluster::managed_via::compute',
         :except        => ['_default', 'single'],
         :relation_name => 'ManagedVia',
         :from_resource => 'spark-cluster',
         :to_resource   => 'compute',
         :attributes    => {}

# securedBy
['spark-cluster'].each do |from|
  relation "#{from}::secured_by::sshkeys",
           :except        => ['_default', 'single'],
           :relation_name => 'SecuredBy',
           :from_resource => from,
           :to_resource   => 'sshkeys',
           :attributes    => {}
end

# Define resources for the Spark master

resource "compute-master",
  :cookbook => "oneops.1.compute",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns" },
  :attributes => { "size"    => "S"
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
      }'
    }
  }

resource "os-master",
  :cookbook => "oneops.1.os",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
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
      }'
    }
  }

resource "file-master",
         :cookbook => "oneops.1.file",
         :design => true,
         :requires => {
             :constraint => "0..*",
             :help => <<-eos
The optional <strong>file</strong> component can be used to create customized files.
For example, you can create configuration file needed for your applications or other components.
A file can also be a shell script which can be executed with the optional execute command attribute.
eos
         }

resource 'user-master',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => { "constraint" => "0..*" }

resource 'java-master',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
           'flavor' => 'oracle',
           'jrejdk' => 'server-jre'
         }

resource "yarn-master",
         :cookbook => "oneops.1.hadoop-yarn-v1",
         :design => false,
         :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "resource manager"
         },
         :payloads => {
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

resource 'spark',
         :cookbook   => spark_cookbook,
#         :source => Chef::Config[:register],
         :design     => true,
         :attributes => {
           "use_yarn" => "false",
           "master_opts" => '[ "-Dspark.kryoserializer.buffer=32m" ]',
           "worker_opts" => '[ "-Dspark.kryoserializer.buffer=32m" ]',
           "spark_config" => '{
                               "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
                               "spark.shuffle.service.enabled": "true",
                               "spark.dynamicAllocation.enabled": "true"
                              }'
         },
         :requires   => {
           :constraint => '1..1',
           :services => '*maven',
           :help       => 'Spark Cluster'
         },
         :monitors => {
           'CheckMaster' => {
             :description => 'Spark Master Process',
             :source      => '',
             :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
             :cmd         => 'check_process!spark!true!none',
             :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
             :metrics     => {
               'up' => metric(:unit => '%', :description => 'Percent Up'),
             },
             :thresholds  => {
               'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
             }
           },
           'LogMaster' => {
             :description => 'Spark Master Log',
             :source => '',
             :chart => {'min' => 0, 'unit' => ''},
             :cmd => 'check_logfiles!logsparkmaster!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
             :cmd_line => '/opt/nagios/libexec/check_spark_log.sh $ARG1$ $ARG2$ "$ARG3$" "$ARG4$"',
             :cmd_options => {
               'logfile' => 'master',
               'warningpattern' => 'WARN',
               'criticalpattern' => 'ERROR'
             },
             :metrics => {
               'logsparkmaster_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
               'logsparkmaster_errors' => metric(:unit => 'errors', :description => 'Errors', :dstype => 'GAUGE'),
               'logsparkmaster_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
               'logsparkmaster_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
             },
             :thresholds => {
               'CriticalLogException' => threshold('1m', 'avg', 'criticals', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1),'unhealthy'),
             }
           },
           'WorkerStatus' => {
             :description => 'Worker Status',
             :source      => '',
             :chart => {'min'=>0},
             :cmd         => 'worker_status',
             :cmd_line    => '/opt/nagios/libexec/worker_status.sh',
             :metrics     => {
               'aliveWorkers' => metric(:unit => 'aliveworkers', :description => 'Workers that are alive', :dstype => 'GAUGE'),
               'downWorkers' => metric(:unit => 'downworkers', :description => 'Workers that are down', :dstype => 'GAUGE'),
               'totalWorkers' => metric(:unit => 'totalworkers', :description => 'Total Workers', :dstype => 'GAUGE')
             },
             :thresholds  => {
               'DownWorkers' => threshold('1m', 'avg', 'downworkers', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1)),
             }
           }
         },
         :payloads => {
           # allMasters - The compute instances for all computes in
           #              the deployment that are Spark masters
           #              Path: Spark master definition (starting point)
           #                    -> depends on compute (master compute def)
           #                    -> realized as compute (compute instance)
           'allMasters' => {
             'description' => 'Spark Master Computes',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Os",
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
                 }
               ]
             }'
           },
           # sparkKeys - All ssh keys used in this deployment.
           #             Path: Spark definition (starting point)
           #                   -> managed via compute (compute definition)
           #                   -> realized as compute (compute instance)
           #                   -> secured by keypair (keypair definition)
           #                   -> realized as keypair (keypair instances)
           'sparkKeys' => {
             'description' => 'Spark Public keys',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "bom.ManagedVia",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedAs",
                   "direction": "to",
                   "targetClassName": "manifest.oneops.1.Compute",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.SecuredBy",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Keypair",
                       "relations": [
                         { "returnObject": true,
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

resource "spark-cassandra",
         :cookbook => "oneops.1.spark-cassandra-v#{spark_version}",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :services => "dns",
             :help => "client"
         },
         :attributes => {
           "spark_version"   => 'auto'
         }

resource "hostname-master",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "dns",
           :help => "hostname dns entry"
         }

resource "volume-work-master",
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
               'chart' => {'min'=>0,'unit'=> 'Percent used'},
               'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
               'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
               'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                              'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
               :thresholds => {
                 'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                 'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
               }
             }
         }



# Define the relationships for the Spark master compute
relation "compute-master::depends_on::secgroup",
    :relation_name => 'DependsOn',
    :from_resource => 'compute-master',
    :to_resource   => 'secgroup',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

#relation "fqdn::depends_on::compute-master",
#    :relation_name => 'DependsOn',
#    :from_resource => 'fqdn',
#    :to_resource   => 'compute-master',
#    :attributes    => {"propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }

# Secure the master compute with the ssh keys
[ 'compute-master'].each do |from|
   relation "#{from}::secured_by::sshkeys",
       :except => [ '_default' ],
       :relation_name => 'SecuredBy',
       :from_resource => from,
       :to_resource   => 'sshkeys',
       :attributes    => { }
end

# Depends relationships for the master

#relation 'fqdn::depends_on::compute-master',
#         :only          => ['_default', 'single'],
#         :relation_name => 'DependsOn',
#         :from_resource => 'fqdn',
#         :to_resource   => 'compute-master',
#         :attributes    => {:flex => false, :min => 1, :max => 1}

[
  {:from => 'volume-work-master', :to => 'compute-master'},
  {:from => 'volume-work-master', :to => 'os-master'},
  {:from => 'hostname-master', :to => 'compute-master'},
  {:from => 'hostname-master', :to => 'os-master'},
  {:from => 'os-master', :to => 'compute-master'},
  {:from => 'java-master', :to => 'os-master'},
  {:from => 'user-master', :to => 'os-master'},
  {:from => 'file-master', :to => 'os-master'},
  { :from => 'spark', :to => 'volume-work-master' },
  { :from => 'spark', :to => 'os-master' },
  {:from => 'spark', :to => 'java-master'},
  {:from => 'spark', :to => 'yarn-master'},
  {:from => 'yarn-master', :to => 'java-master'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
      :relation_name => 'DependsOn',
      :from_resource => link[:from],
      :to_resource   => link[:to],
      :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
  end

# DependsOn relationships that need to have changes propagated to the
# "from" component.
[
  {:from => 'spark', :to => 'yarn-master', :converge => false}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
      :relation_name => 'DependsOn',
      :from_resource => link[:from],
      :to_resource   => link[:to],
      :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => link[:converge], "min" => 1, "max" => 1 }
  end

relation "spark-worker::depends_on::spark",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => 'spark-worker',
    :to_resource   => 'spark',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }

relation "spark-cassandra::depends_on::fqdn",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'spark-cassandra',
    :to_resource   => 'fqdn',
    :attributes    => { "propagate_to" => 'from' }

# The ring depends on the Spark master
#relation "ring::depends_on::spark",
#    :except => [ '_default', 'single' ],
#    :relation_name => 'DependsOn',
#    :from_resource => 'ring',
#    :to_resource   => 'spark',
#    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

# managed_via
[ 'spark', 'spark-cassandra', 'user-master', 'file-master', 'java-master', 'os-master', 'volume-work-master', 'yarn-master' ].each do |from|
  relation "#{from}::managed_via::compute-master",
        :except => [ '_default' ],
        :relation_name => 'ManagedVia',
        :from_resource => from,
        :to_resource   => 'compute-master',
        :attributes    => { }
  end




# Define resources for the Spark client

resource "compute-client",
  :cookbook => "oneops.1.compute",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns" },
  :attributes => { "size"    => "S"
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
      }'
    }
  }

resource "os-client",
  :cookbook => "oneops.1.os",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
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
      }'
    }
  }

resource "file-client",
         :cookbook => "oneops.1.file",
         :design => true,
         :requires => {
             :constraint => "0..*",
             :help => <<-eos
The optional <strong>file</strong> component can be used to create customized files.
For example, you can create configuration file needed for your applications or other components.
A file can also be a shell script which can be executed with the optional execute command attribute.
eos
         }

resource 'user-client',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => { "constraint" => "0..*" }

resource 'java-client',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
           'flavor' => 'oracle',
           'jrejdk' => 'server-jre'
         }

resource "client-yarn",
         :cookbook => "oneops.1.hadoop-yarn-v1",
         :design => false,
         :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "resource manager"
         },
         :payloads => {
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

resource 'spark-client',
         :cookbook   => spark_cookbook,
#         :source => Chef::Config[:register],
         # spark-worker is not present in design view since it reads all Spark settings from the Spark master component
         :design     => false,
         :attributes => {
             "is_client_only" => 'true',
             # No other attributes are configured since Spark-worker gets all settings from the Spark master component
             "spark_custom_download" => " "
         },
         :requires   => {
             :constraint => '1..1',
             :services => '*maven',
             :help       => 'Spark Cluster'
         },
         :monitors => {
         },
         :payloads => {
           # sparkMasters - The compute instances for all computes in
           #                the deployment that are Spark masters
           #                Path: Spark definition (starting point)
           #                      -> depends on Spark (master configs)
           #                      -> depends on compute (master compute def)
           #                      -> realized as compute (compute instance)
           'sparkMasters' => {
             'description' => 'Spark Master Computes',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Spark-v1",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Spark-v1",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.DependsOn",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Os",
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
                     }
                   ]
                 }
               ]
             }'
           },
           # sparkKeys - All ssh keys used in this deployment.
           #             Path: Spark definition (starting point)
           #                   -> managed via compute (compute definition)
           #                   -> realized as compute (compute instance)
           #                   -> secured by keypair (keypair definition)
           #                   -> realized as keypair (keypair instances)
           'sparkKeys' => {
             'description' => 'Spark Public keys',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "bom.ManagedVia",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedAs",
                   "direction": "to",
                   "targetClassName": "manifest.oneops.1.Compute",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.SecuredBy",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Keypair",
                       "relations": [
                         { "returnObject": true,
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

resource "client",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "dns",
           :help => "hostname dns entry"
         }

resource "volume-work-client",
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
               'chart' => {'min'=>0,'unit'=> 'Percent used'},
               'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
               'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
               'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                              'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
               :thresholds => {
                 'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                 'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
               }
             }
         }



# Define the relationships for the Spark client compute
relation "compute-client::depends_on::secgroup",
    :relation_name => 'DependsOn',
    :from_resource => 'compute-client',
    :to_resource   => 'secgroup',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

# Secure the client compute with the ssh keys
[ 'compute-client'].each do |from|
   relation "#{from}::secured_by::sshkeys",
       :except => [ '_default' ],
       :relation_name => 'SecuredBy',
       :from_resource => from,
       :to_resource   => 'sshkeys',
       :attributes    => { }
end

# Depends relationships for the client

#relation 'fqdn::depends_on::compute-master',
#         :only          => ['_default', 'single'],
#         :relation_name => 'DependsOn',
#         :from_resource => 'fqdn',
#         :to_resource   => 'compute-master',
#         :attributes    => {:flex => false, :min => 1, :max => 1}

[
  {:from => 'volume-work-client', :to => 'compute-client'},
  {:from => 'volume-work-client', :to => 'os-client'},
  {:from => 'client', :to => 'compute-client'},
  # Note: Intentionally not including a dependency on os-client to allow the
  #       fqdn componet to use the alias "client" in the name instead of the
  #       vm hostname.
  {:from => 'os-client', :to => 'compute-client'},
  {:from => 'java-client', :to => 'os-client'},
  {:from => 'user-client', :to => 'os-client'},
  {:from => 'file-client', :to => 'os-client'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
      :except => [ '_default' ],
      :relation_name => 'DependsOn',
      :from_resource => link[:from],
      :to_resource   => link[:to],
      :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
  end

[
  { :from => 'spark-client', :to => 'volume-work-client' },
  { :from => 'spark-client', :to => 'os-client' },
  {:from => 'spark-client', :to => 'java-client'},
  {:from => 'spark-client', :to => 'client-yarn'},
  {:from => 'client-yarn', :to => 'java-client'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
      :except => [ '_default' ],
      :relation_name => 'DependsOn',
      :from_resource => link[:from],
      :to_resource   => link[:to],
      :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
  end

[ { :from => 'hadoop-yarn-config', :to => 'os-client' }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

# DependsOn relationships that need to have changes propagated to the
# "from" component.
[
  {:from => 'spark-client', :to => 'client-yarn', :converge => false},
  {:from => 'client-yarn', :to => 'hadoop-yarn-config', :converge => true}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
      :except => [ '_default' ],
      :relation_name => 'DependsOn',
      :from_resource => link[:from],
      :to_resource   => link[:to],
      :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => link[:converge], "min" => 1, "max" => 1 }
  end

relation "spark-client::depends_on::spark",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => 'spark-client',
    :to_resource   => 'spark',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }

# The ring depends on the Spark master
#relation "ring::depends_on::spark",
#    :except => [ '_default', 'single' ],
#    :relation_name => 'DependsOn',
#    :from_resource => 'ring',
#    :to_resource   => 'spark',
#    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

# managed_via
[ 'spark-client', 'user-client', 'file-client', 'java-client', 'os-client', 'volume-work-client', 'client-yarn' ].each do |from|
  relation "#{from}::managed_via::compute-client",
        :except => [ '_default' ],
        :relation_name => 'ManagedVia',
        :from_resource => from,
        :to_resource   => 'compute-client',
        :attributes    => { }
  end
