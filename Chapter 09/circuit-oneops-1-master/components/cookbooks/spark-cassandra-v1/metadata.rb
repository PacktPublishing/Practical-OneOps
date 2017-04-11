name 'Spark-cassandra-v1'
maintainer '@WalmartLabs'
maintainer_email 'paas@email.wal-mart.com'
license 'All rights reserved'
description 'Spark Cassandra Connector (V1 build)'
long_description 'Version 1'
version '1.0.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => ['bom']

# Spark version selection

attribute 'spark_version',
          :description => 'Spark Version',
          :required => 'required',
          :default => 'auto',
          :format => {
            :important => true,
            :help => 'Select the version of Spark to use.',
            :category => '1.General',
            :order => 1,
            :form => { 'field' => 'select', 'options_for_select' => [
              # List of predefined known versions.
              ['Auto Detect','auto'],
              ['Custom','custom'],
              ['Spark 1.6','1.6'],
              ['Spark 1.5','1.5'],
              ['Spark 1.4','1.4'] ]
            }
          }

attribute 'connector_tarball',
          :description => "Location of Connector Drivers",
          :required => false,
          :default => "",
          :format => {
              :category => '1.General',
              :filter => {'all' => {'editable' => 'spark_version:eq:custom'}},
              :help => 'URL location where the connector libraries can be found',
              :order => 2
          }

# Internal attributes not meant for user configuration
attribute 'spark_base',
          :description => "Spark base dir",
          :required => "required",
          :default => "/opt",
          :format => {
              :category => '2.Internal Attributes',
              :filter => {'all' => {'visible' => 'false'}},
              :help => 'Main parent directory for Spark',
              :order => 1
          }

# Actions
