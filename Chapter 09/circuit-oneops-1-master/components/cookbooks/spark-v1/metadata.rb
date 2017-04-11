name 'Spark-v1'
maintainer '@WalmartLabs'
maintainer_email 'paas@email.wal-mart.com'
license 'All rights reserved'
description 'Spark standalone cluster (V1 build)'
long_description 'Version 1'
version '1.0.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => ['bom']

# Spark download
attribute 'spark_custom_download',
          :description => 'Location of Spark distribution',
          :required => 'required',
          :default => ' ',
          :format => {
            :help => 'URL location where the tarball is downloaded from',
            :category => '1.General',
            :order => 1
          }

# Spark version selection

attribute 'spark_version',
          :description => 'Spark Version',
          :required => false,
          :default => ' ',
          :format => {
            :important => true,
            :help => 'The version of Spark that was detected.',
            :category => '1.General',
            :order => 2,
            :filter => {'all' => {'visible' => 'false'}}
          }

attribute 'use_yarn',
    :description => "Submit to YARN",
    :default => 'false',
    :format => {
        :category => '2.Configuration',
        :help => 'Select this box to use a YARN cluster instead of a standalone Spark cluster',
        :order => 1,
        :form => {'field' => 'checkbox'},
        :filter => {'all' => { 'visible' => 'is_client_only:eq:true' } }
    }

attribute 'spark_master',
          :description => "Spark Master",
          :required => false,
          :default => '',
          :format => {
              :help => 'Specify the location of the Spark master(s).',
              :category => '2.Configuration',
              :order => 2,
              :filter => {'all' => {
                                     'visible' => 'is_client_only:eq:true',
                                     'editable' => 'use_yarn:eq:false'
                                   } }
          }

attribute 'worker_cores',
          :description => "Worker Cores",
          :required => "required",
          :default => "2",
          :format => {
              :help => 'Specify the number of cores to use on each Spark worker.',
              :category => '2.Configuration',
              :order => 3,
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

attribute 'worker_memory',
          :description => "Worker Memory",
          :required => "required",
          :default => "2g",
          :format => {
              :help => 'Specify the amount of memory available to assign to Spark executors.',
              :category => '2.Configuration',
              :order => 4,
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

# Executor cores and memory are completely dictated by the Spark
# client.  Leaving these settings in case they are ever configurable at
# the server.
#attribute 'executor_cores',
#          :description => "Executor Cores",
#          :required => "required",
#          :default => "1",
#          :format => {
#              :help => 'Specify the number of cores to use for each Spark executor.',
#              :category => '2.Configuration',
#              :order => 4
#          }
#
#attribute 'executor_memory',
#          :description => "Executor Memory",
#          :required => "required",
#          :default => "1g",
#          :format => {
#              :help => 'Specify the amount of memory to assign to each Spark executor.',
#              :category => '2.Configuration',
#              :order => 5
#          }

attribute 'master_opts',
          :description => 'Master JVM Options',
          :default => '[]',
          :data_type => 'array',
          :format => {
              :help => 'array of JVM_OPTS for Master in spark-env.sh',
              :category => '3.Advanced Configuration',
              :order => 1,
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

attribute 'worker_opts',
          :description => 'Worker JVM Options',
          :default => '[]',
          :data_type => 'array',
          :format => {
              :help => 'array of JVM_OPTS for Worker in spark-env.sh',
              :category => '3.Advanced Configuration',
              :order => 2,
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

# Removing executor options because they are configured completely
# at the Spark client
#attribute 'executor_opts',
#          :description => 'Executor JVM Options',
#          :default => '[]',
#          :data_type => 'array',
#          :format => {
#              :help => 'array of JVM_OPTS for Executor spark-env.sh',
#              :category => '3.Advanced Configuration',
#              :order => 3
#          }

attribute 'spark_config',
          :description => 'Spark Configuration',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Configuration values to add to spark-defaults.conf',
              :category => '3.Advanced Configuration',
              :order => 4
          }

attribute 'zookeeper_servers',
          :description => "Zookeeper Servers",
          :required => false,
          :default => "",
          :format => {
              :help => 'Specify the Zookeeper cluster to synchronize with. Allows the cluster to use workers from other clusters. Example: server1:2181,server2:2181',
              :category => '3.Advanced Configuration',
              :order => 5,
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

attribute 'enable_thriftserver',
          :description => "Enable Thrift Server",
          :default => 'false',
          :format => {
              :help => 'This will generate a keystore and truststore and enable thrift server ssl support',
              :category => '4.Optional Services',
              :order => 1,
              :form => {'field' => 'checkbox'}
          }

attribute 'thrift_server_port',
          :description => "Thrift Server Port",
          :required => false,
          :default => "10000",
          :format => {
              :help => 'Specify the port to use for the thrift server',
              :category => '4.Optional Services',
              :order => 2,
              :filter => {'all' => {'editable' => 'enable_thriftserver:eq:true'} }
          }

attribute 'thrift_ldap_server',
          :description => "Thrift LDAP Server",
          :required => false,
          :default => "",
          :format => {
              :help => 'Specify the server to use for LDAP authentication',
              :category => '4.Optional Services',
              :order => 3,
              :filter => {'all' => {'editable' => 'enable_thriftserver:eq:true'} }
          }

attribute 'thrift_ldap_domain',
          :description => "Thrift LDAP Domain",
          :required => false,
          :default => "",
          :format => {
              :help => 'Specify the LDAP authentication domain for the thrift server',
              :category => '4.Optional Services',
              :order => 4,
              :filter => {'all' => {'editable' => 'enable_thriftserver:eq:true'} }
          }

attribute 'enable_ganglia',
          :description => "Enable Ganglia Monitoring",
          :default => 'false',
          :format => {
              :category => '4.Optional Services',
              :help => 'Select to enable Ganglia monitoring on this cluster',
              :order => 5,
              :form => {'field' => 'checkbox'},
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

attribute 'ganglia_servers',
          :description => 'Ganglia Servers',
          :required => false,
          :default => "",
          :format => {
              :help => 'Specify ganglia servers to point metrics to. Format HOST:PORT',
              :category => '4.Optional Services',
              :filter => {'all' => {'editable' => 'enable_ganglia:eq:true'}},
              :order => 6,
              :filter => {'all' => {'visible' => 'is_client_only:eq:false'} }
          }

# Internal attributes not meant for user configuration
attribute 'spark_base',
          :description => "Spark base dir",
          :required => "required",
          :default => "/opt",
          :format => {
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'Main parent directory for Spark',
              :order => 1
          }

attribute 'hadoop_dir',
          :description => "Hadoop distribution dir",
          :required => "required",
          :default => "/opt/hadoop",
          :format => {
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'The directory where Hadoop is installed.',
              :order => 2
          }

attribute 'hive_dir',
          :description => "Hive distribution dir",
          :required => "required",
          :default => "/opt/hive",
          :format => {
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'The directory where Hive is installed.',
              :order => 3
          }

attribute 'spark_tmp_dir',
          :description => "Spark temp dir",
          :required => "required",
          :default => "/work",
          :format => {
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'The directory where Spark temporary files are stored.',
              :order => 4
          }

attribute 'is_client_only',
          :description => "Client only",
          :required => "required",
          :default => "false",
          :format => {
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'An indication of whether this is a client only installation.',
              :order => 5,
              :form => {'field' => 'checkbox'}
          }

attribute 'enable_historyserver',
          :description => "Enable History Server",
          :default => 'true',
          :format => {
              :help => 'This will enable the spark history server',
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :order => 6,
              :form => {'field' => 'checkbox'}
          }

attribute 'spark_events_dir',
          :description => "Spark events dir",
          :required => "required",
          :default => "/work/events",
          :format => {
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'The directory where the Spark application history files are stored.',
              :order => 7
          }

attribute 'history_server_port',
          :description => "History Server Port",
          :required => false,
          :default => "18080",
          :format => {
              :help => 'Specify the port to use for the history server',
              :category => '5.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :order => 8
          }

# Actions
recipe "repair", "Restart Spark"
