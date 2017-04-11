name             'Supervisord'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
license          'Apache 2.0'
description      'Installs/Configures Supervisord'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

grouping 'bom',
         :access => 'global',
         :packages => ['bom']

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'http_port',
          :description => 'Default http port',
          :required    => 'required',
          :default     => '9001',
          :format      => {
            :help     => 'Port HTTP Server listens to',
            :category => '1.Server',
            :order    => 1
          }

attribute 'http_username',
		  :description => 'Username',
		  :required    => 'required',
		  :default     => 'admin',
		  :format      => {
		  	:help      => 'Username of HTTP Server',
		  	:category  => '1.Server',
		  	:order     => 2
		  }

attribute 'http_password',
		  :description => 'Password',
		  :encrypted   => true,
		  :default     => 'admin',
		  :required    => 'required',
		  :format      => {
		  	:help      => 'Username of HTTP Server',
		  	:category  => '1.Server',
		  	:order     => 3
		  }

attribute 'program_config',
  :description => "Program Config Block",
  :data_type => "text",
  :format => {
    :help => 'Program Config Block to control application',
    :category => '2.Application',
    :order => 1
  }
