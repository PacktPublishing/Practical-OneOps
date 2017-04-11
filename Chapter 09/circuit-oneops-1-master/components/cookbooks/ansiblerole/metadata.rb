name             'Ansiblerole'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
license          'Apache 2.0'
description      'Run Ansible Role'
version          '0.1.0'

grouping 'bom',
         :access => 'global',
         :packages => ['bom']

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'role_name',
          :description => 'ansible role name',
          :grouping => 'bom',
          :required    => 'required',
          :format      => {
            :help     => 'Ansible role name',
            :category => '1.Global',
            :order    => 1
          }

attribute 'role_version',
          :description => 'ansible role name',
          :grouping => 'bom',
          :required    => 'required',
          :default     => 'required',
          :format      => {
            :help     => 'Ansible role name',
            :category => '1.Global',
            :order    => 2
          }

attribute 'ansible_role_name',
          :description => 'ansible role name',
          :required    => 'required',
          :default     => '<place_holder>',
          :format      => {
            :help     => 'Ansible role name',
            :filter => {"all" => {"visible" => "source_yaml:eq:false"}},
            :category => '2.Role',
            :order    => 1
          }

attribute 'ansible_role_version',
          :description => 'ansible role version',
          :required    => 'required',
          :default     => '<place_holder>',
          :format      => {
            :help     => 'Ansible role name',
            :filter => {"all" => {"visible" => "source_yaml:eq:false"}},
            :category => '2.Role',
            :order    => 2
          }

attribute 'source_yaml',
          :description => 'Source YAML',
          :required => 'required',
          :default => 'false',
          :format => {
            :help => 'Source Content',
            :category => '2.Role',
            :form => { 'field' => 'checkbox' },
            :order => 3
          }

attribute 'ansible_role_source',
          :description => 'ansible role source',
          :data_type => "text",
          :default     => '',
          :format      => {
            :help     => 'Ansible role source',
            :filter => {"all" => {"visible" => "source_yaml:eq:true"}},
            :category => '3.Source',
            :order    => 1
          }

attribute 'ansible_role_playbook',
          :description => 'ansible role playbook',
          :required => 'required',
          :data_type => "text",
          :default     => '',
          :format      => {
            :help     => 'Ansible role playbook',
            :category => '4.Playbook',
            :order    => 1
          }