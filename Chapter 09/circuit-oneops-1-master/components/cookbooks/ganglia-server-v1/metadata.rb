name 'Ganglia-server-v1'
maintainer '@WalmartLabs'
maintainer_email 'bfd@walmartlabs.com'
license 'All rights reserved'
description 'Ganglia Server (v1 build)'
long_description 'Version 1'
version '1.0.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => ['bom']

# Grid Name
attribute 'grid_name',
          :description => 'Grid Name',
          :required => 'required',
          :default => 'Ganglia Grid',
          :format => {
            :help => 'Grid name to display in the Ganglia Web UI',
            :category => '1.General',
            :order => 1
          }

attribute 'data_source_map',
          :description => 'Data Sources',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Mapping of ports to data source names',
              :category => '1.General',
              :order => 2
          }

# Web port for the http service
attribute 'gweb_port',
          :description => 'Web port',
          :required => 'required',
          :default => '80',
          :format => {
            :help => 'Web port for the Ganglia server to listen on',
            :category => '1.General',
            :order => 3
          }
          
# Polling interval
attribute 'polling_interval',
          :description => 'Polling Interval',
          :required => 'required',
          :default => '15',
          :format => {
            :help => 'Polling Interval to use for data sources',
            :category => '1.General',
            :order => 4
          }

# Actions
recipe "repair", "Restart Ganglia"
