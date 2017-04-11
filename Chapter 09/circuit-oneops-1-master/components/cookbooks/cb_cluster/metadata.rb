name             'Cb_cluster'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'All rights reserved'
description      'Installs/Configures cb_cluster'
version          '0.1.0'


grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'adminuser',
          :description => "Admin User",
          :required => "optional",
          :default => "Administrator",
          :format => {
              :help => 'Cluster administration username',
              :category => '2.Cluster',
              :order => 2,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'adminpassword',
          :description => "Admin Password",
          :required => "optional",
          :default => "password",
          :format => {
              :help => 'Cluster administration password',
              :category => '2.Cluster',
              :order => 3,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }



recipe "start", "Start Couchbase Cluster"
recipe "stop", "Stop Couchbase Cluster"
recipe "autofailover-enable", "Enable Auto-Failover Couchbase"
recipe "autofailover-disable", "Disable Auto-Failover Couchbase"
recipe "cluster-health-check", "Cluster Health Check"
recipe "cluster-collect-logs", "Collect Couchbase Logs"
recipe "cluster-repair", "Repair Couchbase Cluster"
