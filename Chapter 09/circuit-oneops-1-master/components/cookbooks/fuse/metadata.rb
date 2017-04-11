name                'Fuse'
description         'Installs/Configures Confluent Kafka'
version             '0.1'
maintainer          'OneOps'
maintainer_email    'support@oneops.com'
license             'Apache License, Version 2.0'


grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'user',
		  :description =>'App user',
		  :required =>'required',
		  :default => 'user',
		  :format => {
		  	:important =>true,
		  	:help => 'User is needed for fuse',
		  	:category => '1.Source',
		  	:order => 1
		  }

attribute 'password',
          :description => 'App password',
          :required => 'required',
          :default => 'password',
          :format => {
              :important => true,
              :help => 'Passoword is needed for fuse user',
              :category => '1.Source',
              :order => 1
          }

attribute 'group',
		  :description => 'group',
		  :required =>'required',
		  :default => 'user',
		  :format => {
		  	:important =>true,
		  	:help => 'Group is needed for fuse',
		  	:category => '1.Source',
		  	:order => 1
		  }

attribute 'filename',
		  :description => 'filename',
		  :required =>'required',
		  :default => 'jboss-fuse-6.1.0.redhat-328',
		  :format => {
		  	:important =>true,
		  	:help => 'filename is needed for fuse',
		  	:category => '1.Source',
		  	:order => 1
		  }

attribute 'url',
		  :description => 'url',
		  :required =>'required',
		  :default => 'http://192.168.0.1',
		  :format => {
		  	:important =>true,
		  	:help => 'url is needed for fuse',
		  	:category => '1.Source',
		  	:order => 1
		  }

attribute 'dir',
		  :description => 'file directory',
		  :required =>'required',
		  :default => '/opt',
		  :format => {
		  	:important =>true,
		  	:help => 'File directory is needed for fuse',
		  	:category => '1.Source',
		  	:order => 1
		  }

attribute 'role',
		  :description => 'Role ',
		  :required =>'required',
		  :default => 'admin',
		  :format => {
		  	:important =>true,
		  	:help => 'Role is needed for fuse',
		  	:category => '1.Source',
		  	:order => 1
		  }
attribute 'java home',
      :description => 'Proxy ',
      :required =>'required',
      :default => '/usr/lib/jvm/java',
      :format => {
        :important =>true,
        :help => 'Provide exact java home',
        :category => '3.Java Configuration',
        :order => 1
      }
attribute 'proxy',
		  :description => 'Proxy ',
		  :required =>'required',
		  :default => 'nill',
		  :format => {
		  	:important =>true,
		  	:help => 'Host is needed for maven settings.xml',
		  	:category => '2.Maven Configuration',
		  	:order => 1
		  }

attribute 'proxy_port',
		  :description => 'Proxy port ',
		  :required =>'required',
		  :default => 'nill',
		  :format => {
		  	:important =>true,
		  	:help => 'port is needed for maven settings.xml',
		  	:category => '2.Maven Configuration',
		  	:order => 1
		  }

attribute 'noproxy',
		  :description => 'No proxy ',
		  :required =>'required',
		  :default => 'nill',
		  :format => {
		  	:important =>true,
		  	:category => '2.Maven Configuration',
		  	:order => 1
		  }


attribute 'version',
          :description => 'Select version to Install',
          :required => 'required',
          :default => '1',
          :format => {
              :important => true,
              :help => 'Fuse Version',
              :category => '1.Source',
              :order => 3,
              :form => {'field' => 'select', 'options_for_select' => [
			['6.0.0','6.0.0'],['6.1.0','6.1.0'],['6.1.1','6.1.1'],['6.2.0','6.2.0'],
			['6.2.1','6.2.1'],['6.3.0','6.3.0']


]}
          }
recipe 'add', 'Install fuse'
