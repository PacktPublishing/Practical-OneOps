name             "Inductor"
description      "Inductor"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


# 1.Configuration
attribute 'url',
          :description => "Management URL",
          :required => "required",
          :default => 'http://localhost',
          :format => {
              :important => true,
              :help => 'OneOps management instance URL that identifies where this inductor belongs to',
              :category => '1.Configuration',
              :order => 1
          }

attribute 'mqhost',
          :description => "Message Queue Host",
          :required => "required",
          :default => 'localhost',
          :format => {
              :important => true,
              :help => 'Destination message bus host where the inductor connects to receive work and action orders',
              :category => '1.Configuration',
              :order => 2
          }

attribute 'queue',
          :description => "Queue Location",
          :required => "required",
          :default => '/organization/_clouds/mycloud',
          :format => {
              :important => true,
              :help => 'Name of the queue location this inductor is associated with and responsible for',
              :category => '1.Configuration',
              :order => 3
          }

attribute 'authkey',
          :description => "Authorization Key",
          :required => "required",
          :default => '',
          :format => {
              :help => '',
              :category => '1.Configuration',
              :order => 4
          }

attribute 'collector_domain',
          :description => "Collector Domain",
          :default => '',
          :format => {
              :help => '',
              :category => '1.Configuration',
              :order => 5
          }

attribute 'cert',
          :description => "Logstash Certificate",
          :data_type => 'text',
          :default => '',
          :format => {
              :help => '',
              :category => '1.Configuration',
              :order => 6
          }

attribute 'logstash_hosts',
          :description => "Logstash Hosts",
          :default => '',
          :format => {
              :help => 'Comma separted list in the format host:port',
              :category => '1.Configuration',
              :order => 7
          }

attribute 'perf_collector_cert',
          :description => "Perf Collector Certificate",
          :data_type => 'text',
          :default => '',
          :format => {
              :help => '',
              :category => '1.Configuration',
              :order => 8
          }

attribute 'amq_truststore_location',
          :description => 'TrustStore Location',
          :default => '',
          :format => {
              :help => 'Location of TrustStore used to connect AMQ.',
              :category => '1.Configuration',
              :order => 9
          }
          
attribute 'user',
          :description => "User",
          :required => "required",
          :default => 'ooadmin',
          :format => {
              :help => 'The user which will own and run chef-solo on the inductor.',
              :category => '1.Configuration',
              :order => 10
          }          


# 2.Options
attribute 'ip',
          :description => "IP Attribute",
          :required => "required",
          :default => 'private_ip',
          :format => {
              :help => '',
              :category => '2.Options',
              :order => 1,
              :form => {'field' => 'select', 'options_for_select' => [['Private IP Address', 'private_ip'], ['Public IP Address', 'public_ip']]}
          }

attribute 'dns',
          :description => "Manage DNS",
          :required => "required",
          :default => 'on',
          :format => {
              :help => '',
              :category => '2.Options',
              :order => 2,
              :form => {'field' => 'select', 'options_for_select' => [['on', 'on'], ['off', 'off']]}
          }

attribute 'debug',
          :description => "Debug",
          :required => "required",
          :default => 'off',
          :format => {
              :help => '',
              :category => '2.Options',
              :order => 3,
              :form => {'field' => 'select', 'options_for_select' => [['off', 'off'], ['on', 'on']]}
          }

attribute 'metrics',
          :description => "Metrics Collections",
          :required => "required",
          :default => 'true',
          :format => {
              :help => '',
              :category => '2.Options',
              :order => 4,
              :form => {'field' => 'checkbox'}
          }

# 3.Tuning
attribute 'max',
          :description => "Max Consumers",
          :required => "required",
          :default => '10',
          :format => {
              :help => '',
              :category => '3.Tuning',
              :order => 1
          }

attribute 'maxlocal',
          :description => "Max Local Consumers",
          :required => "required",
          :default => '3',
          :format => {
              :help => '',
              :category => '3.Tuning',
              :order => 2
          }

attribute 'env_vars',
          :description => 'Env Variables',
          :default => '',
          :format => {
              :help => 'Additional env vars to be used for workorder exec. Can be a file or string with key=value content where multiple entries are separated by newline (file) or comma (string)',
              :category => '3.Tuning',
              :order => 3
          }

attribute 'additional_java_args',
          :description => ' Additional java args',
          :default => '',
          :format => {
              :help => 'Additional java args which can be passed for startup /tuning.',
              :category => '3.Tuning',
              :order => 4
          }

# 4.Dependencies
attribute 'inductor_home',
          :description => "Inductor Home Directory",
          :required => "required",
          :default => '/opt/oneops/inductor',
          :format => {
              :help => 'Directory path where inductor software is installed',
              :category => '4.Dependencies',
              :order => 1
          }

recipe "status", "Status"
recipe "start", "Start"
recipe "stop", "Stop"
recipe "enable", "Enable"
recipe "disable", "Disable"
recipe "restart", "Restart"
recipe "repair", "Repair"
