name             'Sensuclient'
maintainer       'sriramKaushik'
maintainer_email 'kaushiksriram100@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures sensuclient'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.1'

grouping 'bom',
         :access => 'global',
         :packages => ['bom']

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'cust_team',
          :description => 'Team/individual email',
          :required    => 'required',
          :format      => {
            :help     => 'team/individual email that should receive the keepalive alerts (only keepalive alerts). Separate multiple emails with comma',
            :category => '1.client',
            :order    => 1
          }

attribute 'keepalive_handlers',
          :description => 'handlers/channel for keepalive alerts',
          :required    => 'required',
	  :default     => 'generic_email_notify',
          :format      => {
            :help     => 'handlers that need to be called for alerts (should be configured in sensu server). This can be slack, email, sms, pagerduty, elastic search, HPOM etc. Separate multiple handlers with comma',
            :category => '1.client',
            :order    => 2
          }

attribute 'cust_subscriptions',
          :description => 'Subscriptions',
          :required    => 'required',
          :default     => 'OneOps',
          :format      => {
            :help     => 'Custom Subscriptionss required. Separate multiple subscriptions with Comma.',
            :category => '1.client',
            :order    => 3
          }

attribute 'endpoint',
          :description => 'Sensu Endpoints',
          :required    => 'required',
          :default     => 'rabbitmqserver.example.com,rabbitmqserver2.example.com',
          :format      => {
            :help     => 'sensu endpoints are the message queue endpoints. Separate multiple values with Comma. max of 6. defaults to port 5671. For user password please change in the rabbitmq_*.json files under files/default in the cookbook',
            :category => '2.endpoints',
            :order    => 1
          }

attribute 'sensu_vhost_password',
          :description => 'vhost pwd',
          :required    => 'required',
	  :encrypted   => true,
          :default     => 'topsecret_wontwork',
          :format      => {
            :help     => 'vhost password for sensu user in rabbitmq. check with rabbitmq admin',
            :category => '2.endpoints',
            :order    => 2
          }

attribute 'sensu_client_version',
          :description => 'Sensu RPM/deb version',
          :required    => 'required',
          :default     => 'sensu-0.21.0-2',
          :format      => {
            :help     => 'provide the sensu client version that needs to be installed.',
            :category => '2.endpoints',
            :order    => 3
          }

attribute 'sensu_client_cert',
          :description => 'Certificate',
          :data_type => 'text',
          :required => 'required',
          :default => "",
          :format  => {
            :help => 'Enter the sensu client certificate - client/cert.pem',
            :category => '3.keys and certs',
            :order   => 1
          }

attribute 'sensu_client_key',
          :description => 'Key',
          :data_type => 'text',
          :encrypted => true,
          :required => 'required',
          :default => "",
          :format  => {
            :help => 'Enter the sensu client key - client/key.pem',
            :category => '3.keys and certs',
            :order   => 2
          }

attribute 'sensu_plugin_repo',
          :description => 'provide a URL of the sensu plugins. Should be tar.gz',
          :required    => 'required',
          :default     => 'http://something.example.com/sensu-community-oneops.tar.gz',
          :format      => {
            :help     => 'defaults to http://something.example.com/sensu-community-oneops.tar.gz',
            :category => '3.plugins',
            :order    => 1
          }


recipe "restart", "Restart Sensu Client"
recipe "stop", "Stop Sensu client"
recipe "delete", "delete sensu client"
recipe "updateplugins", "update sensu-client plugins"
