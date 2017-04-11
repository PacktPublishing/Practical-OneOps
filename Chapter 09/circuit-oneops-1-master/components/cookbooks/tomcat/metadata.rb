name                "Tomcat"
description         "Installs/Configures tomcat"
version             "0.1"
maintainer          "OneOps"
maintainer_email    "support@oneops.com"
license             "Apache License, Version 2.0"
depends             "shared"
depends             "javaservicewrapper"

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


# installation attributes
attribute 'install_type',
          :description => "Installation Type",
          :required => "required",
          :default => "repository",
          :format => {
              :category => '1.Global',
              :help => 'Select the type of installation - standard OS repository package or custom build from source code',
              :order => 1,
              :form => {'field' => 'select', 'options_for_select' => [['Repository package', 'repository'], ['Binary Tarball', 'binary']]}
          }

attribute 'tomcat_install_dir',
          :description => "Tomcat Installation Directory",
          :required => "required",
          :default => "/opt",
          :format => {
              :category => '1.Global',
              :help => 'Directory where tomcat gets installed',
              :order => 2
          }

attribute 'mirrors',
          :description => "Binary distribution mirrors",
          :data_type => 'array',
          :default => '["http://archive.apache.org/dist","http://apache.cs.utah.edu" ]',
          :format => {
              :category => '1.Global',
              :help => 'Apache distribution compliant mirrors - uri without /tomcat/tomcat-x/... path.If not defined will use cloud apache mirror service',
              :order => 3
          }

attribute 'version',
          :description => "Version",
          :required => "required",
          :default => "7.0",
          :format => {
              :important => true,
              :help => 'Version of Tomcat',
              :category => '1.Global',
              :order => 4,
              :form => {'field' => 'select', 'options_for_select' => [['6.0', '6.0'], ['7.0', '7.0']]},
              :pattern => "[0-9\.]+"
          }

attribute 'build_version',
          :description => "Build Version",
          :required => "required",
          :default => "70",
          :format => {
            :important => true,
            :category => '1.Global',
            :help => 'Tomcat minor version number.  Example: Version=7, Build Version=75 will install Tomcat 7.0.75',
            :order => 5,
            :form => {'field' => 'select', 'options_for_select' => [['42', '42'], ['62', '62'], ['67', '67'], ['68', '68'], ['70', '70'], ['72', '72'], ['73', '73'], ['75', '75']]}
          }



attribute 'webapp_install_dir',
          :description => "Webapps Directory",
          :default => "/opt/tomcat7/webapps",
          :format => {
              :help => 'Specify the directory path where tomcat will look for web applications (webapps)',
              :category => '1.Global',
              :order => 6
          }


attribute 'tomcat_user',
          :description => "User",
          :format => {
              :help => 'System user to use for the tomcat process (Note: if empty will default to os-specific tomcat or tomcat version selected )',
              :category => '2.Server',
              :order => 1
          }

attribute 'tomcat_group',
          :description => "Group",
          :format => {
              :help => 'System group to use for the tomcat process (Note: if empty will default to os-specific tomcat or tomcat version selected )',
              :category => '2.Server',
              :order => 2
          }
attribute 'protocol',
          :description => 'Sets the protocol to handle incoming traffic for Connector',
          :required => 'required',
          :default => 'HTTP/1.1',
          :format => {
              :help => 'Sets "protocol" attribute in server.xml connector.[Blocking Java connector=org.apache.coyote.http11.Http11Protocol,Non blocking Java connector=org.apache.coyote.http11.Http11NioProtocol,The APR/native connector=org.apache.coyote.http11.Http11AprProtocol]. Refer. /tomcat-7.0-doc/config/http.html ',
              :category => '2.Server',
              :order => 3,
              :form => {'field' => 'select', 'options_for_select' => [['HTTP/1.1','HTTP/1.1'],['Blocking Java connector', 'org.apache.coyote.http11.Http11Protocol'], ['Non blocking Java connector', 'org.apache.coyote.http11.Http11NioProtocol'],['The APR/native connector', 'org.apache.coyote.http11.Http11AprProtocol']]},
          }

attribute 'http_connector_enabled',
          :description => "Enable HTTP Connector",
          :default => "true",
          :format => {
                :category => '2.Server',
                :help => 'Enable HTTP Connector (Non SSL) Connector',
                :order => 4,
                :form => {'field' => 'checkbox'}
            }

attribute 'advanced_connector_config',
          :description => 'Additional attributes needed for connector config.',
          :data_type => 'hash',
          :required => 'required',
          :default => '{"connectionTimeout":"20000","maxKeepAliveRequests":"100"}',
          :format => {
              :help => 'The additional attribute in connector element separated by space  attr_name1="value1" attr_name2="value2" will be appended to connector element in server.xml  ',
              :category => '2.Server',
              :order => 5
          }

attribute 'port',
          :description => "HTTP Port",
          :required => "required",
          :default => "8080",
          :format => {
              :help => 'Port tomcat listens on for incoming HTTP requests',
              :category => '2.Server',
              :order => 6,
              :filter => {'all' => {'visible' => 'http_connector_enabled:eq:true'}},
              :pattern => "[0-9]+"
          }

attribute 'ssl_port',
          :description => "SSL Port",
          :required => "required",
          :default => "8443",
          :format => {
              :help => 'Secure port tomcat listens on for incoming requests',
              :category => '2.Server',
              :order => 7,
              :pattern => "[0-9]+"
          }

attribute 'server_port',
          :description => "Server port",
          :required => "required",
          :default => "8005",
          :format => {
              :help => 'Tomcat management server port',
              :category => '2.Server',
              :order => 8,
              :pattern => "[0-9]+"
          }

attribute 'ajp_port',
          :description => "AJP port",
          :required => "required",
          :default => "8009",
          :format => {
              :help => 'Tomcat AJP port',
              :category => '2.Server',
              :order => 9,
              :pattern => "[0-9]+"
          }

attribute 'environment',
          :description => 'Environment Variables',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :help => 'Environment variables here will override ones set in builds',
              :category => '2.Server',
              :order => 10
          }


attribute 'logfiles_path',
          :description => 'Logfiles Path',
          :required => 'required',
          :default => '/log/apache-tomcat/',
          :format => {
              :help => 'Directory for catalina.out and access.log',
              :category => '2.Server',
              :order => 11
          }

#autoDeploy
attribute 'autodeploy_enabled',
	  :description => "Enable autoDeploy",
	  :default => 'false',
          :format => {
    	  :help => 'Disable / Enable autoDeploy',
	    :category => '2.Server',
	    :form => { 'field' => 'checkbox' },
	    :order => 12
  }

#context.xml
attribute 'context_enabled',
  :description => "Add context",
  :default => 'false',
  :format => {
    :help => 'Disable / Enable Additional context',
    :category => '2.Server',
    :form => { 'field' => 'checkbox' },
    :order => 13
  }

  attribute 'context_tomcat',
          :description => 'Default Values for context.xml',
          :default => IO.read(File.join(File.dirname(__FILE__), 'files/context.xml')),
	         :data_type => 'text',
          :format => {
              :help => 'Values defined here will override the existing context values',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'context_enabled:eq:true'}},
              :order => 14
 }

attribute 'advanced_security_options',
          :description => 'Advanced Security Options',
          :default => 'false',
          :format => {
              :help => 'Display/Hide advanced security options.  Hiding the options does not disable or default the settings.',
              :category => '2.Server',
              :form => { 'field' => 'checkbox' },
              :order => 15
          }

attribute 'tlsv1_protocol_enabled',
          :description => 'Enable TLSv1',
          :default => 'true',
          :format => {
              :help => 'If SSL/TLS is enabled by adding a certificate and keystore, this attribute determines if the TLSv1 protocol and ciphers are enabled.  Enabling TLSv1 is considered a security vulnarability.  Only TLSv1.1 and above should be used in production.',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 16,
          }

attribute 'tlsv11_protocol_enabled',
          :description => 'Enable TLSv1.1',
          :default => 'true',
          :format => {
              :help => 'If SSL/TLS is enabled by adding a certificate and keystore, this attribute determines if the TLSv1.1 protocol and ciphers are enabled.',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 17,
          }

attribute 'tlsv12_protocol_enabled',
          :description => 'Enable TLSv1.2',
          :default => 'true',
          :format => {
              :help => 'If SSL/TLS is enabled by adding a certificate and keystore, this attribute determines if the TLSv1.2 protocol and ciphers are enabled.',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 18,
          }

attribute 'enable_method_get',
          :description => 'Enable GET HTTP method',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the get http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 19
          }

attribute 'enable_method_put',
          :description => 'Enable PUT HTTP method',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the put http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 20
          }

attribute 'enable_method_post',
          :description => 'Enable POST HTTP method',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the post http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 21
          }

attribute 'enable_method_delete',
          :description => 'Enable DELETE HTTP method',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the delete http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 22
          }

attribute 'enable_method_connect',
          :description => 'Enable CONNECT HTTP method',
          :default => 'true',
          :format => {
              :help => 'Disable / Enable the connect http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 23
          }

attribute 'enable_method_options',
          :description => 'Enable OPTIONS HTTP method',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the options http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 24
          }

attribute 'enable_method_head',
          :description => 'Enable HEAD HTTP method',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the head http method',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 25
          }

attribute 'enable_method_trace',
          :description => 'Enable TRACE HTTP method',
          :default => 'false',
              :format => {
              :help => 'Disable / Enable the trace http method. Note: this applies to HTTP, HTTPS, and AJP Connectors',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 26
          }

attribute 'server_header_attribute',
          :description => 'Modify server HTTP header value.',
          :required => 'required',
          :default => 'web',
          :format => {
              :help => 'Modify the value of the server attribute in the HTTP header.',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :order => 27,
              :editable => true
          }

attribute 'enable_error_report_valve',
          :description => 'Enable Error Report Valve',
          :default => 'true',
              :format => {
              :help => 'Disable / Enable the error report valve that hides data about the platform in default Tomcat generated error pages',
              :category => '2.Server',
              :filter => {'all' => {'visible' => 'advanced_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 28
          }


attribute 'executor_name',
          :description => 'Name',
          :required => 'required',
          :default => 'tomcatThreadPool',
          :format => {
              :help => 'The name used to reference this pool in other places in server.xml. The name is required and must be unique.',
              :category => '3.Executor',
              :order => 1
          }

attribute 'max_threads',
          :description => 'Max Threads',
          :required => 'required',
          :default => '50',
          :format => {
              :help => 'The max number of active threads in this pool, default is 50',
              :category => '3.Executor',
              :order => 2,
              :pattern => '[0-9]+'
          }

attribute 'min_spare_threads',
          :description => 'Min Spare Threads',
          :required => 'required',
          :default => '25',
          :format => {
              :help => 'The minimum number of threads always kept alive, default is 25',
              :category => '3.Executor',
              :order => 3,
              :pattern => '[0-9]+'
          }


attribute 'java_options',
          :description => "Java Options",
          :default => "-Djava.awt.headless=true",
          :format => {
              :help => 'JVM command line options',
              :category => '4.Java',
              :order => 1
          }

attribute 'system_properties',
          :description => "System Properties",
          :data_type => 'hash',
          :default => "{}",
          :format => {
              :important => true,
              :help => 'Key value pairs for -D args to the jvm',
              :category => '4.Java',
              :order => 2
          }

attribute 'startup_params',
          :description => "Startup Parameters",
          :data_type => 'array',
          :default => '["+UseConcMarkSweepGC"]',
          :format => {
              :help => '-XX arguments (without the -XX: in the values)',
              :category => '4.Java',
              :order => 3
          }

attribute 'mem_max',
          :default => '128M',
          :description => "Max Heap Size",
          :format => {
              :important => true,
              :help => 'Max Memory Heap Size',
              :category => '4.Java',
              :order => 4
          }

attribute 'mem_start',
          :default => '128M',
          :description => "Start Heap Size",
          :format => {
              :help => 'Start Memory Heap Size',
              :category => '4.Java',
              :order => 5
          }

attribute 'stop_time',
          :default => '45',
          :description => "Specify the time limit to Shut down the  server .",
          :format => {
              :help => 'Stop(in seconds)',
              :category => '4.Java',
              :order => 6,
              :pattern => "[0-9]+"

          }


attribute 'use_security_manager',
          :description => "Use Security Manager",
          :default => "false",
          :format => {
              :category => '5.Security',
              :order => 1,
              :help => '',
              :form => {'field' => 'checkbox'}
          }

attribute 'policy',
          :description => "Policy",
          :data_type => 'text',
          :format => {
              :category => '5.Security',
              :order => 2,
              :help => 'Local permissions and grants for tomcat web applications'
          },
          :default => <<-eos
grant codeBase "file:${catalina.base}/webapps/-" {
        permission java.security.AllPermission;
};
eos

attribute 'access_log_dir',
          :default => 'logs',
          :description => "Specify the directory in which access log files will be created .",
          :format => {
              :help => 'Specify the directory in which access log files will be created ',
              :category => '6.Access Log',
              :order => 1
          }
attribute 'access_log_prefix',
          :default => 'access_log',
          :description => "Log File prefix. .",
          :format => {
              :help => 'Log file prefix. ',
              :category => '6.Access Log',
              :order => 2
          }

attribute 'access_log_file_date_format',
          :default => "yyyy-MM-dd",
          :description => "Date format to place in log file name.",
          :format => {
              :help => 'Specify the Log file date format. ',
              :category => '6.Access Log',
              :order => 3
          }
attribute 'access_log_suffix',
          :default => '.log',
          :description => "The suffix to be  added to log file filenames.",
          :format => {
              :help => 'Specify the Log file suffix. ',
              :category => '6.Access Log',
              :order => 4
          }
attribute 'access_log_pattern',
          :default => '%h %l %u %t &quot;%r&quot; %s %b %D %F',
          :description => "Access log Formating layout ",
          :format => {
              :help => 'Specify the Log file pattern. ',
              :category => '6.Access Log',
              :order => 5
          }

attribute 'pre_shutdown_command',
          :default => '',
          :description => 'Command to be executed before tomcat shutdown is invoked.',
          :data_type => 'text',
          :format => {
              :help => 'Command to be executed before catalina stop is invoked. As an example in case of redundant environment, It can be used to post request (using curl)  which can trigger an ecv failure(response code 503). This will allow lb to take this instance out of traffic. ',
              :category => '7.Advanced',
              :order => 1
          }

attribute 'time_to_wait_before_shutdown',
          :default => '30',
          :description => 'Time(in seconds) to wait after the pre shut down is executed. ',
          :format => {
              :help => 'Time it will wait before catalina stop is executed after execution of pre shut down.',
              :category => '7.Advanced',
              :pattern => '[0-9]+',
              :order => 2
          }

attribute 'post_startup_command',
          :default => '',
          :description => 'Script to be executed after tomcat has been started.',
          :data_type => 'text',
          :format => {
              :help => 'Command to be executed after tomcat has been started. It should return 0 for successful execution and 1 for failure, which will cause tomcat startup to fail',
              :category => '7.Advanced',
              :order => 3
          }

attribute 'polling_frequency_post_startup_check',
          :default => '1',
          :description => 'Time(in seconds) to wait before executing post start up command. ',
          :format => {
              :help => 'This will control at what frequency the post startup script will be executed.',
              :category => '7.Advanced',
              :pattern => '[0-9]+',
              :order => 4
          }

attribute 'max_number_of_retries_for_post_startup_check',
          :default => '15',
          :description => 'Max. Number of retries for executing post startup command.  ',
          :format => {
              :help => 'The post start up script will be retried for max number of retries , executing the post start up script as per polling frequency ',
              :category => '7.Advanced',
              :pattern => '[0-9]+',
              :order => 5
          }

recipe 'status', 'Tomcat Status'
recipe 'start', 'Start Tomcat'
recipe 'stop', 'Stop Tomcat'
recipe 'force-stop', 'Skips PreShutDownHook'
recipe 'force-restart', 'Skips PreShutDownHook'
recipe 'restart', 'Restart Tomcat'
recipe 'repair', 'Repair Tomcat'
recipe 'debug', 'Debug Tomcat'
recipe 'validateAppVersion', 'Server started after app deployment'
recipe 'threaddump','Java Thread Dump'
