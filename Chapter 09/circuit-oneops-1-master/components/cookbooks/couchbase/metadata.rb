name              "Couchbase"
description       "Installs/Configures couchbase"
version           "0.1"
maintainer        "OneOps"
maintainer_email  "support@oneops.com"
license           "Apache License, Version 2.0"


grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


# Couchbase mirror
attribute 'mirrors',
          :description => 'Mirrors',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '1.Global',
              :help => "Couchbase binary distribution mirrors - uri without /version/artifact.rpm path. Uses official or cloud mirror if it's empty.",
              :order => 1,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'message_enterprise',
          :description => "Important Message",
          :default => "Couchbase Enterprise edition is supported by Couchbase. Support could be purchased on www.couchbase.com.",
          :data_type => 'text',
          :format => {
              :help => 'Important Message',
              :category => '1.Global',
              :order => 2,
              :filter => {'all' => {'visible' => 'edition:neq:community'}},
              :editable => false,
          }

attribute 'message_community',
          :description => "Important Message",
          :default => "Couchbase community edition is not supported by Couchbase. Support is available on Couchbase forums.",
          :data_type => 'text',
          :format => {
              :help => 'Important Message',
              :category => '1.Global',
              :order => 2,
              :filter => {'all' => {'visible' => 'edition:eq:community'}},
              :editable => false,
          }

attribute 'distributionurl',
          :description => 'Binary Distribution',
          :default => 'http://packages.couchbase.com/releases/',
          :format => {
            :category => '1.Global',
            :help => "Couchbase binary distribution mirrors. Select official or cloud mirror.",
            :order => 3,
          }

attribute 'edition',
        :description => "Edition",
        :required => "required",
        :default => "community",
        :format => {
            :help => 'Edition. By default it uses Community edition. For Enterprise, please contact www.couchbase.com',
            :category => '1.Global',
            :order => 4,
            :editable => true,
#            :filter => {'all' => {'visible' => 'false'}},
            :form => {'field' => 'select', 'options_for_select' => [['Community', 'community']]}
        }

# New entries should follow the format 'community_<Version Number>'
attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => 'community_3.0.1',
          :format => {
            :help => 'Version of Couchbase',
            :category => '1.Global',
            :order => 5,
            :filter => {'all' => {'visible' => 'true'}},
            :form => {'field' => 'select', 'options_for_select' => [
                ['Community 3.0.1', 'community_3.0.1']
              ]
            }
          }

attribute 'upgradecouchbase',
          :description => "Upgrade CouchBase",
          :default => 'false',
          :format => {
              :help => 'If selected, CouchBase Server will be upgraded to selected version',
              :category => '1.Global',
              :order => 6,
              :form => { 'field' => 'checkbox' }
          }

attribute 'arch',
          :description => 'Arch',
          :required => 'required',
          :default => 'x86_64',
          :format => {
              :help => 'Processor architecture. x86_64 (64 bit) or x86 (32 bit).',
              :category => '1.Global',
              :order => 7,
	            :editable => false
          }

attribute 'checksum',
        :description => "Checksum",
        :format => {
        :category => '1.Global',
        :help => 'SHA-256 checksum of the file',
        :editable => false,
        :order => 8,
        :filter => {'all' => {'visible' => 'false'}}
        }

# cluster
attribute 'port',
          :description => "Cluster Management Port",
          :default => "8091",
          :format => {
              :help => 'Couchbase web console and cluster management port',
              :category => '2.Cluster',
              :order => 1,
              :editable => false,
          }

attribute 'adminuser',
          :description => "Admin User",
          :required => "required",
          :default => "Administrator",
          :format => {
              :help => 'Cluster administration username',
              :category => '2.Cluster',
              :order => 2
          }

attribute 'adminpassword',
          :description => "Admin Password",
          :encrypted => true,
          :required => "required",
          :default => "password",
          :format => {
              :help => 'Cluster administration password with min length of 6',
              :category => '2.Cluster',
              :order => 3,
              :pattern => "^.{6,}$"
          }


attribute 'pernoderamquotamb',
          :description => "RAM quota percentage per node",
          :default => "80%",
          :format => {
              :help => 'Per node RAM quota percentage',
              :category => '2.Cluster',
              :order => 4,
              :editable => true,
              :form => {'field' => 'select', 'options_for_select' => [['80%', '80%'], ['60%', '60%']]}
          }

# Buckets
attribute 'datapath',
          :description => "Buckets Data Path",
          :default => "/opt/couchbase/data",
          :format => {
              :help => 'Directory path where bucket data files will be stored',
              :category => '3.Buckets',
              :order => 4,
              :editable => true
          }

# Settings
attribute 'updatenotification',
          :description => "CouchBase update notification.",
          :default => 'false',
          :format => {
              :help => 'Directory path where bucket data files will be stored',
              :category => '4.Settings',
              :order => 1,
              :form => { 'field' => 'checkbox' }
          }


attribute 'autofailovertime',
          :description => "Auto Fail Over in seconds",
          :default => '120',
          :format => {
              :help => 'The timeout before the auto-failover process is started when a cluster node failure is detected',
              :category => '4.Settings',
              :order => 2

          }

attribute 'autocompaction',
          :description => "Auto Compaction % Level",
          :default => '75',
          :format => {
              :help => 'Database Fragmentation at which point compaction is triggered. Range 20% to 80%',
              :category => '4.Settings',
              :order => 3

          }

attribute 'host',
          :description => "Email Server Host",
          :default => 'smtp',
          :format => {
              :help => 'SMTP Host',
              :category => '4.Settings',
              :order => 4

          }

attribute 'emailport',
          :description => "Email Server Port",
          :default => '25',
          :format => {
              :help => 'SMTP Port',
              :category => '4.Settings',
              :order => 5

          }


attribute 'sender',
          :description => "Sender email",
          :default => 'couchbase@example.com',
          :format => {
              :help => 'Sender Email eg: couchbase@example.com',
              :category => '4.Settings',
              :order => 6

          }

attribute 'recipents',
          :description => "Email Recipients",
          :default => 'admin@example.com',
          :format => {
              :help => 'Recipients addresses with comma separated',
              :category => '4.Settings',
              :order => 7

          }



recipe "status", "Couchbase Status"
recipe "start", "Start Couchbase"
recipe "stop", "Stop Couchbase"
recipe "restart", "Restart Couchbase"
recipe "repair", "Repair Couchbase"
recipe "remove-from-cluster", "Remove Couchbase server from cluster"
recipe "add-to-cluster", "Add Couchbase server to cluster"
