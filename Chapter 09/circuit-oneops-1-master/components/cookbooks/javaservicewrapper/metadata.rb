name                "Javaservicewrapper"
description         "Installs/Configures YAJSW"
version             "0.1"
maintainer          "OneOps"
maintainer_email    "support@oneops.com"
license             "Apache License, Version 2.0"
depends             "shared"

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'app_title',
          :description => "Application Name",
           :required => "required",
          :default => "/app",
          :format => {
              :category => '1.Global',
              :help => 'The daemon service name will be based on this.',
              :order => 1 
          }

attribute 'main_class',
          :description => "Java Main Class (Fully Qualified)",
          :default => "",
          :format => {
              :category => '1.Global',
              :help => 'Java Main Class (Fully Qualified)',
              :order => 2
          }

attribute 'executable_jar',
          :description => "Executable Jar for -jar option",
          :default => "",
          :format => {
              :category => '1.Global',
              :help => 'Executable Jar for -jar option',
              :order => 3
          }

attribute 'working_dir',
          :description => "Working Directory",
          :default => "",
          :format => {
              :category => '1.Global',
              :help => 'Directory where your application needs to run',
              :order => 4
          }

attribute 'start_main_args',
          :description => "Args to the main method",
          :data_type => 'array',
          :format => {
              :category => '1.Global',
              :help => 'Arguments to the main method',
              :order => 5
          }

attribute 'java_params',
          :description => "Java parameters like -D",
          :data_type => 'array',
          :format => {
              :category => '1.Global',
              :help => 'Java parameters like -D -Xmx etc',
              :order => 6
          }

attribute 'java_classpath_params',
          :description => "Java classpath tokens",
          :data_type => 'array',
          :format => {
              :category => '1.Global',
              :help => 'Java class path tokens. Add them individually',
              :order => 7
          }

attribute 'environment_vars',
	  :description => 'Environment Variables',
	  :data_type => 'hash',
	  :format => {
		  :help => 'Environment variables here will override ones set in builds',
	          :category => '1.Global',
	          :order => 8
          }

attribute 'jmx',
          :description => "Enable JMX",
          :default => "true",
          :format => {
              :category => '1.Global',
              :order => 9,
              :help => '',
              :form => {'field' => 'checkbox'}
          }

attribute 'jmx_port',
          :description => "JMX port",
          :default => "1099",
          :format => {
              :category => '1.Global',
	      :order => 10,
              :help => '',
	      :filter => {'all' => {'visible' => 'jmx:eq:true'}}
          }

attribute 'additional_wrapper_text',
          :description => "Append to wrapper.conf",
          :default => "",
          :data_type => 'text',
          :format => {
              :category => '1.Global',
              :help => 'Text to append at the end of wrapper.conf',
              :order => 11
          }

attribute 'wrapper_stop_text',
          :description => "Append to stop.conf",
          :default => "",
          :data_type => 'text',
          :format => {
              :category => '1.Global',
              :help => 'Text to append at the end of stop.conf',
              :order => 12
          }

attribute 'url',
          :description => "Package location URL",
          :required => "required",
          :default => "",
          :format => {
              :category => '1.Global',
              :help => 'Package location URL',
              :order => 13
          }

attribute 'install_dir',
          :description => "Wrapper Install Directory",
          :required => "required",
          :default => "/app",
          :format => {
              :category => '1.Global',
              :help => 'Wrapper Install Directory',
              :order => 14
          }

attribute 'as_user',
	:description => "Deploy as user",
	:format => {
	:help => 'System user to run the deploy as (root if not specified)',
	:category => '1.Global',
	:order => 15
	}

attribute 'as_group',
	:description => "Deploy as group",
	:format => {
	:help => 'System group to run the deploy as (root if not specified)',
	:category => '1.Global',
	:order => 16
	}

recipe "configure", "Configure"
recipe "start", "Start"
recipe "stop", "stop"
recipe "restart", "Restart"
recipe "repair", "Repair"
