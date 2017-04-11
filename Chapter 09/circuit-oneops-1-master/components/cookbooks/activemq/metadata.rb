name 'Activemq'
maintainer 'OneOps'
maintainer_email    "support@oneops.com"
license             "Apache License, Version 2.0"
description 'Installs/Configures activemq messaging resources'
version '1.0.0'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'installpath',
          :description => 'Installation directory',
          :default => '/opt',
          :format => {
              :help => 'ActiveMQ installation directory',
              :category => '1.ActiveMQ',
              :order => 1
          }

attribute 'datapath',
          :description => "Data Directory for KahaDB",
          :default => "/data",
          :required => 'required',
          :format => {
              :help => 'Data Directory for KahaDB if ephermeral storage is used',
              :category => '1.ActiveMQ',
              :order => 2,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '5.13.0',
          :format => {
              :important => true,
              :help => 'Version of ActiveMQ (eg: 5.13.0)',
              :category => '1.ActiveMQ',
              :order => 3,
          }

attribute 'transportconnector',
          :description => 'Transport Connectors',
          :required => 'required',
          :data_type => 'hash',
          :default => '{
             "nio":"nio://0.0.0.0:61616?maximumConnections=1000&amp;needClientAuth=false"
          }',
          :format => {
              :help => 'Transport Connectors for different protocols such as tcp, nio, ssl, openwire, amqp, mqtt',
              :category => '1.ActiveMQ',
              :order => 4
          }

attribute 'logsize',
          :description => 'Log file Size (MB)',
          :default => '5',
          :format => {
              :help => 'ActiveMQ Logging file size (MB).',
              :category => '1.ActiveMQ',
              :order => 5
          }

 attribute 'logpath',
          :description => 'Log file path',
          :default => '/var/log/activemq',
          :format => {
              :help => 'ActiveMQ  Log file path.',
              :category => '1.ActiveMQ',
              :order => 6
          }

attribute 'maxconnections',
         :description => 'Maximum Connections',
         :default => '1000',
         :format => {
             :help => 'Maximum connections for each transport connector.',
             :category => '1.ActiveMQ',
             :filter => {'all' => {'visible' => 'false'}},
             :order => 7
         }

attribute 'environment',
          :description => 'Environment Variables',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :help => 'Environment variables for ActiveMQ instance',
              :category => '1.ActiveMQ',
              :order => 8
          }

attribute 'authenabled',
          :description => 'Enable console authentication ',
          :default => 'true',
          :format => {
              :category => '2.Administration',
              :help => 'Enable console authentication',
              :form => {'field' => 'checkbox'},
              :order => 1
          }

attribute 'adminusername',
          :description => 'Admin Username',
          :default => 'admin',
          :format => {
              :category => '2.Administration',
              :filter => {'all' => {'visible' => 'authenabled:eq:true'}},
              :help => 'Admin Username for Server administration (default=admin)',
              :order => 2
          }

attribute 'adminpassword',
          :description => 'Admin Password',
          :encrypted => true,
          :default => 'admin',
          :format => {
              :category => '2.Administration',
              :help => 'Admin user password (default=admin)',
              :filter => {'all' => {'visible' => 'authenabled:eq:true'}},
              :order => 3
          }

attribute 'adminconsoleport',
          :description => 'Web Console Port',
          :required => 'required',
          :default => '8161',
          :format => {
              :help => 'Admin Console Port',
              :category => '2.Administration',
              :order => 4
          }

attribute 'jmxusername',
          :description => 'JMX Username',
          :default => 'admin',
          :format => {
              :category => '2.Administration',
              :help => 'JMX Username',
              :order => 5
          }

attribute 'jmxpassword',
          :description => 'JMX Password',
          :encrypted => true,
          :default => 'activemq',
          :format => {
              :category => '2.Administration',
              :help => 'JMX Password',
              :order => 6
          }
attribute 'advisorysupport',
          :description => 'Advisory Support',
          :default => 'false',
          :format => {
              :help => 'Advisory messages are event message regarding what is happening on JMS provider as well as what''s happening with producers, consumers and destinations.',
              :category => '2.Administration',
              :form => {'field' => 'checkbox'},
              :filter => {'all' => {'visible' => 'false'}},
              :order => 7
          }
attribute 'operationssupport',
          :description => 'Adhoc Operations Support',
          :default => 'false',
          :format => {
              :help => 'Enable in admin console operations such as creating, deleting, or purging messages from destination. It is recommended to keep this feature disabled as those operations should be through OneOps; Enabling it will result in OneOps deployment out of synch with ActiveMQ.',
              :category => '2.Administration',
              :form => {'field' => 'checkbox'},
              :order => 8
          }

attribute 'restapisupport',
          :description => 'Admin REST API Support',
          :default => 'false',
          :format => {
              :help => 'Enable admin REST api allows operations such as destination creation or deletion via Jolokia REST call. It is recommended to keep this feature disabled as actions via REST API will bypass OneOps, resulting in OneOps deployment out of synch with ActiveMQ.',
              :category => '2.Administration',
              :form => {'field' => 'checkbox'},
              :order => 9
          }

attribute 'pwdencyenabled',
          :description => 'Enable Password Encryption',
          :default => 'true',
          :format => {
              :category => '2.Administration',
              :help => 'Enable Password Encryption for Users.',
              :form => {'field' => 'checkbox'},
              :order => 10
          }
attribute 'custombeans',
          :description => "Beans Support",
          :data_type => "text",
          :format => {
            :help => 'Beans needed for the configuration. ',
            :category => '2.Administration',
            :order => 11
          }

attribute 'customplugins',
      :description => "Plugins Support",
      :data_type => "text",
      :format => {
        :help => 'Plugins needed for the configuration. ',
        :category => '2.Administration',
        :order => 12
        }

attribute 'kahadbattributes',
      :description => "Kahadb Attributes",
      :data_type => "hash",
      :default => '{
             "enableJournalDiskSyncs":"true"
      }',
      :format => {
        :help => 'Configuration attributes for Kahadb element. ',
        :category => '2.Administration',
        :order => 13
      }

attribute 'brokerattributes',
      :description => "Broker Attributes",
      :data_type => "hash",
      :default => '{
             "useJmx":"true",
             "advisorySupport":"false"
          }',
      :format => {
        :help => 'Configuration attributes for Broker.',
        :category => '2.Administration',
        :order => 14
      }

attribute 'wrapperjavaprop',
      :description => "Additional Java parameters",
      :data_type => "array",
      :default => '["-Dorg.apache.activemq.UseDedicatedTaskRunner=true","-Djava.util.logging.config.file=logging.properties", "-Djava.security.auth.login.config=%ACTIVEMQ_CONF%/login.config","-Dactivemq.home=%ACTIVEMQ_HOME%","-Dactivemq.base=%ACTIVEMQ_BASE%","-Dactivemq.conf=%ACTIVEMQ_CONF%", "-Dactivemq.data=%ACTIVEMQ_DATA%", "-Dcom.sun.management.jmxremote.authenticate=true" ]',
      :format => {
        :help => 'Additional Java parameters to pass to Java when it is launched. These are not parameters for your application, but rather parameters for the JVM. ',
        :category => '2.Administration',
        :order => 15
      }

attribute 'initmemory',
          :description => 'Init Memory (MB)',
          :required => 'optional',
          :default => '512',
          :format => {
              :help => 'Minimum Heap size of ActiveMq (MB)',
              :category => '3.Memory and Storage',
              :order => 1
          }

attribute 'maxmemory',
          :description => 'Max Memory (MB)',
          :required => 'optional',
          :default => '2048',
          :format => {
              :help => 'Maximum Heap size of ActiveMq (MB)',
              :category => '3.Memory and Storage',
              :order => 2
          }

attribute 'storeusage',
          :description => 'Store Usage (MB)',
          :default => '8192',
          :format => {
              :help => 'The storage size limit at which producers of persistent messages will be blocked.',
              :category => '3.Memory and Storage',
              :order => 3
          }

 attribute 'tempusage',
          :description => 'Temp Usage (MB)',
          :default => '2048',
          :format => {
              :help => 'The temp storage size limit for non-persistent messages overflow to avoid out of memory issue.',
              :category => '3.Memory and Storage',
              :order =>4
          }

attribute 'jvmheap',
         :description => 'Percent of JVM Heap',
         :default => '60',
         :format => {
             :help => 'Percent of JVM Heap for messages (message memory).',
             :category => '3.Memory and Storage',
             :order =>5
         }

attribute 'adminconsolesecure',
          :description => 'Enable SSL',
          :default => 'false',
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Enable SSL',
              :form => {'field' => 'checkbox'},
              :order => 1
}

attribute 'needclientauth',
          :description => 'Enable SSL Client Auth',
          :default =>'false',
          :format => {
              :category => '4.Authentication and Authorization',
              :help => "Flag for the client authentication in SSL transport (if needClientAuth=false, the client won't need a keystore but requires a truststore in order to validate the broker's certificate).",
              :filter => {'all' => {'visible' => 'false'}},
              :order => 2,
              :form => {'field' => 'checkbox'}
          }

attribute 'adminconsolekeystore',
          :description => 'Keystore absolute path',
          :default => '$OO_LOCAL{keystorepath}',
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Keystore absolute path. (eg: ${installedpath}/activemq/conf/broker.ks)',
              :filter => {'all' => {'visible' => 'adminconsolesecure:eq:true'}},
              :order => 3
          }

attribute 'adminconsolekeystorepassword',
          :description => 'Keystore password',
          :encrypted => true,
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Keystore password',
              :filter => {'all' => {'visible' => 'adminconsolesecure:eq:true'}},
              :order => 4
          }

attribute 'authtype',
          :description => 'Auth Type',
          :default => 'JAAS',
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Authentication and Authorization type',
              :form => {'field' => 'select', 'options_for_select' => [['JAAS', 'JAAS'], ['Simple', 'Simple'], ['None','None']]},
              :order => 5
}

attribute 'brokerauthenabled',
          :description => 'Broker Secure',
          :default => 'false',
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Broker is Secure',
              :form => {'field' => 'checkbox'},
              :order => 6,
            :filter => {'all' => {'visible' => 'false'}},
          }

attribute 'brokerusername',
          :description => 'Broker Username',
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Username for the Broker Authentication (For: Multiple Users use **Broker Users**)',
              :filter => {'all' => {'visible' => 'authtype:eq:Simple'}},
              :order => 7
          }

attribute 'brokerpassword',
          :description => 'Broker Password',
          :encrypted => true,
          :format => {
              :category => '4.Authentication and Authorization',
              :help => 'Password for the Broker Authentication',
              :filter => {'all' => {'visible' => 'authtype:eq:Simple'}},
              :order => 8
          }

attribute 'users',
          :description => "Broker Users",
          :data_type => "hash",
          :default => '{"readonly":"readonly"}',
          :format => {
            :help => 'Users credentials for messaging. eg.username:password.',
            :category => '4.Authentication and Authorization',
            :order => 9
          }

attribute 'mirrors',
          :description => 'Binary distribution mirror urls',
          :required => 'required',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '5.Mirror',
              :help => 'Apache distribution compliant mirrors',
              :order => 1
          }

attribute 'checksum',
          :description => 'Binary distribution checksum',
          :format => {
              :category => '5.Mirror',
              :help => 'MD5 checksum of the binary file',
              :order => 2
          }

recipe "status", "Activemq Status"
recipe "repair", "Activemq Repair"
recipe "start", "Activemq Start"
recipe "stop", "Activemq Stop"
