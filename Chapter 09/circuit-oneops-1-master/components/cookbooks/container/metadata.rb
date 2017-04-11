name             "Container"
description      "Container spec"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]



# Run
attribute 'command',
  :description => "Command",
  :format => {
    :help => 'Command to use as entrypoint to start the container',
    :category => '1.Run',
    :order => 1
  }

attribute 'args',
  :description => "Arguments",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Command arguments to use as entrypoint to start the container',
    :category => '1.Run',
    :order => 2
  }

attribute 'env',
  :description => "Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => '',
    :category => '1.Run',
    :order => 3
  }

attribute 'ports',
  :description => "Ports",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of port name (a DNS_LABEL) and value as <port-number>[/<port-protocol>]. Example ssh=22/tcp',
    :important => true,
    :category => '1.Run',
    :order => 4
  }


# Resources
attribute 'cpu',
  :description => "CPU",
  :format => {
    :help => 'CPUs to reserve for each container. Default is whole CPUs; scale suffixes (e.g. 100m for one hundred milli-CPUs) are supported',
    :category => '2.Resources',
    :order => 1
  }

attribute 'memory',
  :description => "Memory",
  :format => {
    :help => 'Memory to reserve for each container. Default is bytes; binary scale suffixes (e.g. 100Mi for one hundred mebibytes) are supported',
    :category => '2.Resources',
    :order => 2
  }


# bom only
attribute 'nodes',
  :description => "Cluster Nodes",
  :grouping => 'bom',
  :data_type => "array",
  :format => {
    :help => 'List of cluster nodes/hosts used for the set',
    :category => '3.Cluster',
    :order => 1
  }

attribute 'node_ports',
  :description => "Node Forwarded Ports",
  :grouping => 'bom',
  :data_type => "hash",
  :format => {
    :help => 'Forwarded Ports on the Cluster Nodes. Internal Port => External Port',
    :category => '3.Cluster',
    :order => 2
  }

recipe "repair", "Repair"
