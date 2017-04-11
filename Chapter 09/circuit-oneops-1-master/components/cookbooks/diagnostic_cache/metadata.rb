name                "Diagnostic_cache"
description         "Installs/Configures Diagnostic Cache Logs"
version             "0.1"
maintainer          "Cache"
maintainer_email    "support@oneops.com"
license             "Copyright OneOps, All rights reserved."


grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

grouping 'bom',
         :access => "global",
         :packages => [ 'bom' ]


attribute 'logfiles_path',
          :description => 'Logfiles Path',
          :required => 'required',
          :default => '/opt/diagnostic-cache/log/diagnostic-cache.log',
          :format => {
              :help => 'Directory diagnostic-cache for cache.log',
              :category => '1.Global',
              :order => 1
          }

attribute 'graphite_servers',
          :description => "Graphite Servers",
          :data_type => 'array',
          :default => '[]',
          :format => {
              :help => 'Enter a list of graphite servers. ex. graphite.server.com:2003',
              :category => '1.Global',
              :order => 2
          }

attribute 'graphite_prefix',
          :description => "Graphite Metrics Prefix",
          :default => '',
          :format => {
              :help => 'Enter a  graphite metrics prefix',
              :category => '1.Global',
              :order => 3
          }

attribute 'graphite_logfiles_path',
          :description => 'Graphite Metrics Tool Logfiles Path',
          :required => 'required',
          :default => '/opt/diagnostic-cache/log/graphite-metrics-tool.log',
          :format => {
              :help => 'Directory for graphite metrics tool logs',
              :category => '1.Global',
              :order => 4
          }

recipe "repair", "Repair Couchbase"
