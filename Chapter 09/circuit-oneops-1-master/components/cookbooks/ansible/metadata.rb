name             'Ansible'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
license          'Apache 2.0'
description      'Installs/Configures ansible'
version          '0.1.0'

grouping 'bom',
         :access => 'global',
         :packages => ['bom']

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'ansible_version',
          :description => 'Version',
          :required    => 'required',
          :default     => '2.2.0.0',
          :format      => {
            :help     => 'Ansible version to install',
            :category => '1.Ansible',
            :order    => 1
          }

attribute 'pip_config',
          :description => 'pip_config',
          :required => 'required',
          :default => 'false',
          :format => {
            :help => 'Pip config',
            :category => '2.Pip',
            :form => { 'field' => 'checkbox' },
            :order => 1
          }

attribute 'pip_config_content',
          :description => 'pip_config',
          :data_type => "text",
          :default     => "[global]
index-url = https://pypi.python.org/simple",
          :format      => {
            :help     => 'Pip Config',
            :filter => {"all" => {"visible" => "pip_config:eq:true"}},
            :category => '2.Pip',
            :order    => 2
          }
          