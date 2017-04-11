name 'Solrcloud'
license 'Apache License, Version 2.0'
version '1.0.0'

grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

grouping 'bom',
  :access => 'global',
  :packages => ['bom']



attribute 'solr_url',
  :description => 'Solr binary distribution base url',
  :required => 'required',
  :default => 'https://archive.apache.org/dist/lucene',
  :format => {
    :help => 'Nexus version of Solr binary distribution ',
    :category => '1.SolrCloud',
    :order => 1
  }

attribute 'solr_package_type',
  :description => 'Solr binary distribution package type ',
  :required => 'required',
  :default => 'solr',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['solr', 'solr']]},
    :order => 2
  }

attribute 'solr_format',
  :description => 'Solr binary distribution format (.tgz)/(.tar.gz)',
  :required => 'required',
  :default => 'tgz',
  :format => {
    :help => 'Nexus formats of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['tgz', 'tgz'],['tar.gz', 'tar.gz']]},
    :order => 3
  }

attribute 'solr_version',
  :description => 'Solr binary distribution version',
  :required => 'required',
  :default => '4.10.3.2',
  :format => {
    :help => 'Nexus version of Solr binary distribution ',
    :category => '1.SolrCloud',
    :form => {'field' => 'select', 'options_for_select' => [['4.10.3', '4.10.3'],['4.10.3.2', '4.10.3.2'],['5.0.0', '5.0.0'],['5.1.0', '5.1.0'],['5.2.0', '5.2.0'],['5.2.1', '5.2.1'],['5.3.0', '5.3.0'],['5.3.1', '5.3.1'],['5.3.2', '5.3.2'],['5.4.0', '5.4.0'],['5.4.1', '5.4.1'],['5.5.0', '5.5.0'],['5.5.1', '5.5.1'],['6.0.0', '6.0.0'],['6.0.1', '6.0.1'],['6.1.0', '6.1.0']]},
    :order => 4
  }

attribute 'join_replace_node',
  :description => "Join replaced node to the cluster",
  :default => "false",
  :help => 'Depending on the maxShardsPerNode parameter , this feature chooses the shards which has least no of replicas and adds the replaced node as a replica for the given list of collections. User should replace each node at a time and can verify whether the node join as a replica to the cluster.',
  :format => {
    :category => '1.SolrCloud',
    :order => 5,
    :form => {'field' => 'checkbox'}
  }

attribute 'collection_list',
  :description => "List of collections",
  :format => {
    :category => '1.SolrCloud',
    :filter => {'all' => {'visible' => 'join_replace_node:eq:true'}},
    :order => 6,
  }

attribute 'config_name',
  :description => 'Name of default Solr config',
  :default => 'defaultconf',
  :format => {
    :help => 'Name of default Solr config',
    :category => '1.SolrCloud',
    :order => 6
  }

attribute 'custom_config_url',
  :description => 'Nexus URL of Custom Solr Config (.jar)',
  :default => 'customconfigurl',
  :format => {
    :help => 'Custom Solr Config Url in nexus',
    :category => '1.SolrCloud',
    :order => 7
  }

attribute 'custom_config_name',
  :description => 'Name of custom Solr Config',
  :default => 'customconfigname',
  :format => {
    :help => 'Custom Prod Config Name',
    :category => '1.SolrCloud',
    :order => 8
  }

attribute 'installation_dir_path',
  :description => 'installation directory',
  :default => '/app',
  :format => {
    :help => 'installation directory',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 9
  }

attribute 'data_dir_path',
  :description => 'data directory',
  :default => '/app/solrdata',
  :format => {
    :help => 'data directory',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 10
  }

attribute 'port_no',
  :description => 'port no',
  :default => '8983',
  :format => {
    :help => 'port no',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 11
  }

attribute 'gc_tune_params',
  :description => 'GC TUNE params',
  :data_type => 'array',
  :default => '["NewRatio=3"]',
  :format => {
    :help => 'GC_TUNE_params',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 12
  }

attribute 'gc_log_params',
  :description => 'GC LOG params',
  :data_type => 'array',
  :default => '["-verbose:gc"]',
  :format => {
    :help => 'GC_LOG_params',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 13
  }

attribute 'solr_opts_params',
  :description => 'SOLROPTS params',
  :data_type => 'array',
  :default => '["solr.autoSoftCommit.maxTime=3000"]',
  :format => {
    :help => 'SOLR_OPTS_params',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 14
  }

attribute 'solr_max_heap',
  :description => 'solr max heap',
  :default => '-Xmx512m',
  :format => {
    :help => 'solr_max_heap',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 15
  }

attribute 'solr_min_heap',
  :description => 'solr min heap',
  :default => '-Xms512m',
  :format => {
    :help => 'solr_min_heap',
    :category => '2.SolrCloud Standalone server Paramerters',
    :filter => {"all" => {"visible" => "solr_version:eq:6.1.0 || solr_version:eq:6.0.1 || solr_version:eq:6.0.0 || solr_version:eq:5.0.0 || solr_version:eq:5.1.0 || solr_version:eq:5.2.0 || solr_version:eq:5.2.1 || solr_version:eq:5.3.0 || solr_version:eq:5.3.1 || solr_version:eq:5.3.2 || solr_version:eq:5.4.0 || solr_version:eq:5.4.1 || solr_version:eq:5.5.0 || solr_version:eq:5.5.1"}},
    :order => 16
  }

attribute 'zk_select',
  :description => 'Internal/External',
  :required => 'required',
  :default => 'ExternalEnsemble',
  :format => {
      :help => 'Internal/External',
      :category => '3.Zookeeper',
      :order => 17,
      :form => {'field' => 'select', 'options_for_select' => [['ExternalEnsemble', 'ExternalEnsemble'],['InternalEnsemble-SameAssembly', 'InternalEnsemble-SameAssembly']]}
  }

attribute 'zk_host_fqdns',
  :description => 'External ZK hosts',
  :default => 'zk_host_fqdns',
  :format => {
      :help => "Location of External ZK hosts",
      :category => '3.Zookeeper',
      :filter => {'all' => {"visible" => "zk_select:eq:ExternalEnsemble"}},
      :order => 18
  }

attribute 'platform_name',
  :description => 'Platform Name',
  :default => 'zookeeper',
  :format => {
    :help => 'Platform Name',
    :category => '3.Zookeeper',
    :filter => {'all' => {"visible" => "zk_select:eq:InternalEnsemble-SameAssembly"}},
    :order => 19
  }

attribute 'nodeip',
  :description => 'Node IPAddress',
  :grouping => 'bom',
  :format => {
      :important => true,
      :help => 'Node IPAddress',
      :category => '4.Other',
      :order => 21
  }

attribute 'node_solr_version',
  :description => 'solr version',
  :grouping => 'bom',
  :format => {
      :important => true,
      :help => 'Current solr version',
      :category => '4.Other',
      :order => 22
  }

attribute 'node_solr_portnum',
  :description => 'solr portno',
  :grouping => 'bom',
  :format => {
      :important => true,
      :help => 'solr port number',
      :category => '4.Other',
      :order => 23
  }


recipe "addreplica",
  :description => 'Adds Replica To Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Adds as a replica to the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ShardName" => {
      "name" => "ShardName",
      "description" => "Shard of a collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "createcollection",
  :description => 'Creates Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Creates the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "NumberOfShards" => {
      "name" => "NumberOfShards",
      "description" => "Number of shards in the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ReplicationFactor" => {
      "name" => "ReplicationFactor",
      "description" => "Replication Factor for the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "MaxShardsPerNode" => {
      "name" => "MaxShardsPerNode",
      "description" => "Max shards per node in the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ConfigName" => {
      "name" => "ConfigName",
      "description" => "ConfigName to create the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }


recipe "modifycollection",
  :description => 'Modifies Collection',
  :args => {
    "PhysicalCollectionName" => {
      "name" => "PhysicalCollectionName",
      "description" => "Modifies the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "AutoAddReplicas" => {
      "name" => "PhysicalCollectionName",
      "description" => "Modifies the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "ReplicationFactor" => {
      "name" => "ReplicationFactor",
      "description" => "Replication Factor for the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "MaxShardsPerNode" => {
      "name" => "MaxShardsPerNode",
      "description" => "Max shards per node in the collection",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "uploadsolrconfig",
  :description => 'Uploads solr config to zookeeper',
  :args => {
    "CustomConfigJar" => {
      "name" => "CustomConfigJar",
      "description" => "CustomConfigJar",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    },
    "CustomConfigName" => {
      "name" => "CustomConfigName",
      "description" => "CustomConfigName",
      "defaultValue" => "",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "dynamicschemaupdate",
  :description => 'This action updates managed schema and uploads to Zookeeper.',
  :args => {
    "collection_name" => {
      "name" => "collection_name",
      "description" => "collection name",
      "required" => true,
      "defaultValue" => "",
    },
    "modify_schema_action" => {
      "name" => "modify_schema_action",
      "description" => "schema action ex: ( add-field/replace-field/delete-field/add-dynamic-field/delete-dynamic-field/replace-dynamic-field/add-field-type/delete-field-type/replace-field-type/add-copy-field/delete-copy-field )",
      "required" => true,
      "defaultValue" => "",
    },
    "payload" => {
      "name" => "payload",
      "description" => "payload format ex: {key1:value1,key1:value1},{key2:value2,key2:value2}",
      "required" => true,
      "defaultValue" => "",
    },
    "updateTimeoutSecs" => {
      "name" => "updateTimeoutSecs",
      "description" => "update timeout seconds",
      "defaultValue" => "",
    }
  }

recipe "configupdate",
  :description => 'This action updates the solr-config and uploads to Zookeeper.',
  :args => {
    "collection_name" => {
      "name" => "collection_name",
      "description" => "collection name",
      "required" => true,
      "defaultValue" => "",
    },
    "common_property" => {
      "name" => "common_property",
      "description" => "common property ex: ( updateHandler.autoSoftCommit.maxTime )",
      "required" => true,
      "defaultValue" => "",
    },
    "value" => {
      "name" => "value",
      "description" => "property value ex: ( 12000 )",
      "defaultValue" => "",
    }
  }


recipe "status", "Solr Status"
recipe "start", "Start Solr"
recipe "stop", "Stop Solr"
recipe "restart", "Restart Solr"
recipe "updateclusterstate", "Deletes all the dead/down replicas and update cluster state"

