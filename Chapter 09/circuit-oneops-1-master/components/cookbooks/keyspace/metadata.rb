name             "Keyspace"
description      "Installs/Configures Keyspace"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'keyspace_name',
  :description => "Keyspace Name",
  :required => "required",
  :default => "db",
  :format => {
    :important => true,
    :help => 'Keyspace Name used in the create keyspace <keyspace name> context',
    :category => '1.Global',
    :order => 1
  }

attribute 'replication_factor',
  :description => "Replication Factor",
  :required => "required",
  :default => "3",
  :format => {
    :important => true,
    :help => 'Replication Factor',
    :category => '1.Global',
    :order => 2
  }

attribute 'placement_strategy',
  :description => "Placement Strategy",
  :required => "required",
  :default => "SimpleStrategy",
  :format => {
    :important => true,
    :help => 'Determines how replicas for a keyspace will be distributed among nodes in the ring.',
    :category => '1.Global',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['SimpleStrategy','SimpleStrategy'],
      ['NetworkTopologyStrategy','NetworkTopologyStrategy']] }
  }

attribute 'extra',
  :description => "Additional statements added to the create keystore cassandra_cli -f run",
  :data_type => 'text',
  :format => {
    :help => 'Additional statements added to the create keystore cassandra_cli -f run',
    :category => '1.Global',
    :order => 4
  }

recipe "repair", "Repair"
