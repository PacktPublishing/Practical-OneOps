name              "Es"
description       "Installs/Configures ElasticSearch With LB"
version           "0.1"
maintainer        "OneOps"
maintainer_email  "support@oneops.com"
license           "Copyright OneOps, All rights reserved."

depends "ark"

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'mirrors',
          :description => 'Mirrors',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '1.Global',
              :help => "ElasticSearch binary distribution mirror. Uses official or cloud mirror if it's empty.",
              :order => 1
          }

attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '1.7.1',
          :format => {
              :important => true,
              :help => 'Version of ElasticSearch',
              :category => '2.Global',
              :order => 1,
              :form => {'field' => 'select', 'options_for_select' => [['1.1.1', '1.1.1'],['1.3.2', '1.3.2'],['1.4.1', '1.4.1'],['1.4.4', '1.4.4'],['1.5.0', '1.5.0'],['1.5.1', '1.5.1'],['1.7.1', '1.7.1'],['2.0.0', '2.0.0'],['2.4.0', '2.4.0']]}
          }

attribute 'cluster_name',
          :description => 'Name',
          :default => 'elasticsearch',
          :format => {
              :help => 'Name of the elastic search cluster',
              :category => '2.Cluster',
              :important => true,
              :order => 1
          }

attribute 'awareness_attribute',
          :description => 'Awareness Attribute',
          :default => "cloud",
          :format => {
              :help => 'Cluster Awareness Attribute',
              :category => '2.Cluster',
              :order => 2
          }

attribute 'cloud_rack_zone_map',
          :description => "Map of Cloud to Rack/Zone",
          :default => "{}",
          :data_type => "hash",
          :format => {
            :help => '"Map of Cloud to Rack/Zone for cluster awareness',
            :category => '2.Cluster',
            :order => 3
  }

attribute 'shards',
  :description => "Number of shards",
  :default => '5',
  :format => {
    :important => true,
    :help => 'Number of shards of an index(5 by default)',
    :category => '3.Index',
    :order => 1
  }

attribute 'replicas',
  :description => "Number of replicas",
  :default => '1',
  :format => {
    :important => true,
    :help => 'Number of replicas of an index(1 by default)',
    :category => '3.Index',
    :order => 2
  }

attribute 'memory',
  :description => "Allocated Memory(MB)",
  :format => {
    :important => true,
    :help => 'Allocated Memory to elastic search.By default is computed as one half of total available memory on the machine',
    :category => '4.Memory',
    :order => 1
  }

attribute 'http_port',
  :description => "Http port",
  :default => '9200',
  :format => {
    :help => 'Port to listen for HTTP traffic',
    :category => '5.Http',
    :order => 1
  }


attribute 'install_dir',
  :description => "Install Dir",
  :default => '/usr/local',
  :format => {
    :help => 'Path of the elastic search-installation directory',
    :category => '6.Paths',
    :important => true,
    :order => 1
  }

attribute 'data_dir',
  :description => "Data Dir",
  :default => '/data/elasticsearch',
  :format => {
    :help => 'Path of the elastic search-data directory',
    :category => '6.Paths',
    :important => true,
    :order => 2
  }

attribute 'conf_dir',
  :description => "Config Dir",
  :default => '/usr/local/etc/elasticsearch',
  :format => {
    :help => 'Path of the elastic-search config directory',
    :category => '6.Paths',
    :order => 3
  }

attribute 'log_dir',
  :description => "Log Dir",
  :default => '/usr/local/var/log/elasticsearch',
  :format => {
    :help => 'Path of the elastic-search log directory',
    :category => '6.Paths',
    :order => 4
  }

attribute 'pid_file_path',
  :description => "Pid File Path",
  :default => '/usr/local/var/run',
  :format => {
    :help => 'Path of the elastic-search pid file',
    :category => '6.Paths',
    :order => 5
  }
  
attribute 'recover_after_nodes',
  :description => "Recover after nodes",
  :default => '',
  :format => {
    :help => 'Start recovery after min nodes eligible',
    :category => '7.Gateway',
    :order => 1
  }
  
attribute 'recover_after_time',
  :description => "Recover after time",
  :default => '',
  :format => {
    :help => 'Start recovery after time',
    :category => '7.Gateway',
    :order => 2
  }  

attribute 'expected_nodes',
  :description => "Expected nodes",
  :default => '',
  :format => {
    :help => 'Start recovery after nodes in cluster',
    :category => '7.Gateway',
    :order => 3
  }  
    
  
attribute 'master',
  :description => "Master",
  :default => 'true',
  :format => {
    :help => 'Master Node ?',
    :category => '8.Node',
    :order => 1
  } 
  
attribute 'data',
  :description => "Data",
  :default => 'true',
  :format => {
    :help => 'Data Node ?',
    :category => '8.Node',
    :order => 2
  }   
  
attribute 'custom_config',
  :description => 'Custom Configurations',
  :default => '{}',
  :data_type => 'hash',
  :format => {
    :help => 'Custom Configurations',
    :category => '9.Custom',
    :order => 1
}  

recipe "status", "Node Status"
recipe "stop", "Stop Es"
recipe "start", "Start Es"
recipe "restart", "Restart Es"
recipe "repair", "Repair Es"
