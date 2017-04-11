name             "Cluster"
description      "Cluster installation and configuration"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest']

grouping 'bom',
 :access => "global",
 :packages => [ 'bom' ]

attribute 'keepalive',
  :description => "Keepalive Interval",
  :default => '30',
  :format => {
    :help => 'Cluster heartbeat keepalive interval in seconds',
    :category => '1.Global',
    :order => 1,
  } 

attribute 'mode',
  :description => "Cluster Mode",
  :default => 'active-standby',
  :format => {
    :help => 'Select the desired cluster mode of operation',
    :category => '1.Global',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['Active/Standby','active-standby'],['Active/Active','active-active']] }
  }

# elastic-ip is only public_ip which would cause traffic to route thru the nat box for vpc  
# so we have to use dns for failover
attribute 'shared_type',
  :description => "Shared Resource Type",
  :required => 'required',
  :default => 'ip',
  :format => {
    :help => 'Select the type of the shared failover resource (IP Address or DNS Name)',
    :category => '1.Global',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [['IP','ip'],['DNS','dns']] }
  }
  
attribute 'shared_ip',
  :description => "Shared IP",
  :grouping => 'bom',  
  :default => '',
  :format => {
    :help => 'Current shared IP used by the cluster',
    :category => '2.Operations',
    :order => 1
  }    
  
attribute 'dns_record',
  :description => "DNS Record value used by FQDN",
  :grouping => 'bom',
  :format => {
    :help => 'DNS Record value used by FQDN',
    :category => '2.Operations',
    :order => 2
  }
  
recipe "repair", "Repair"