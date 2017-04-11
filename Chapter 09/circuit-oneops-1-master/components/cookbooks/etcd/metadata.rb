name              'Etcd'
description       'Etcd is a distributed, consistent key-value store for shared configuration and service discovery.'
version           '1.0.0'
maintainer        'OneOps'
maintainer_email  'support@oneops.com'
license           'Apache License, Version 2.0'

grouping 'default',
         :access => 'global',
         :packages => %w(base mgmt.catalog mgmt.manifest catalog manifest bom)

grouping 'bom',
         :access => 'global',
         :packages => ['bom']


attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '2.3.7',
          :format => {
              :important => true,
              :help => 'Etcd version',
              :category => '1.Binary',
              :order => 1
          }

attribute 'mirror',
          :description => 'Binary distribution mirror',
          :default => '',
          :format => {
              :important => true,
              :help => 'Etcd binary package repository. Uses official repo (https://github.com/coreos/etcd/releases) if empty.',
              :category => '1.Binary',
              :order => 2
          }

attribute 'security_enabled',
          :description => 'SSL Enable',
          :default => 'false',
          :format => {
              :help => 'Use SSL/TLS for authentication.',
              :category => '2.Authentication',
              :form => {:field => 'checkbox'},
              :order => 1
          }

attribute 'security_certificate',
          :description => 'Server Certificate',
          :data_type => 'text',
          :default => '',
          :format => {
              :help => 'Enter the certificate content to be used (Note: usually this is the content of the *.crt file).',
              :category => '2.Authentication',
              :filter => {:all => {:visible => 'security_enabled:eq:true'}},
              :order => 2,
              :editable => true
          }

attribute 'security_key',
          :description => 'Server Key',
          :data_type => 'text',
          :encrypted => true,
          :default => '',
          :format => {
              :help => 'Enter the certificate key content (Note: usually this is the content of the *.key file).',
              :category => '2.Authentication',
              :filter => {:all => {:visible => 'security_enabled:eq:true'}},
              :order => 3,
              :editable => true
          }

attribute 'security_ca_certificate',
          :description => 'CA Certificate',
          :data_type => 'text',
          :default => '',
          :format => {
              :help => 'Enter the CA certificate keys to be used to be used to trust certs signed only by this CA.',
              :category => '2.Authentication',
              :filter => {:all => {:visible => 'security_enabled:eq:true'}},
              :order => 4,
              :editable => true
          }

attribute 'security_path',
          :description => 'Directory Path',
          :default => '/var/lib/certs',
          :format => {
              :help => 'Directory path where the certificate files should be saved',
              :category => '2.Authentication',
              :filter => {:all => {:visible => 'security_enabled:eq:true'}},
              :order => 5
          }

# Member Flags
attribute 'member_flags',
          :description => 'Member Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '3.Member',
              :help => 'Etcd member flags',
              :order => 1
          }

# Clustering Flags
attribute 'cluster_flags',
          :description => 'Cluster Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '4.Cluster',
              :help => 'Etcd cluster flags',
              :order => 1
          }

# Proxy Flags
attribute 'proxy_flags',
          :description => 'Proxy Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '5.Proxy',
              :help => 'Etcd proxy flags',
              :order => 1
          }

# Security Flags
attribute 'security_flags',
          :description => 'Security Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '6.Security',
              :help => 'Etcd security flags',
              :order => 1
          }

# Logging Flags
attribute 'logging_flags',
          :description => 'Logging Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '7.Logging',
              :help => 'Etcd logging flags',
              :order => 1
          }

# Unsafe Flags
attribute 'unsafe_flags',
          :description => 'Unsafe Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '8.Unsafe',
              :help => 'Please be CAUTIOUS when using unsafe flags because it will break the guarantees given by the consensus protocol',
              :order => 1
          }

# Experimental Flags
attribute 'experimental_flags',
          :description => 'Experimental Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '9.Experimental',
              :help => 'Etcd experimental flags',
              :order => 1
          }

# Miscellaneous Flags
attribute 'miscellaneous_flags',
          :description => 'Miscellaneous Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '10.Miscellaneous',
              :help => 'Etcd miscellaneous flags',
              :order => 1
          }

# Profiling Flags
attribute 'profiling_flags',
          :description => 'Profiling Flags',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '11.Profiling',
              :help => 'Etcd profiling flags',
              :order => 1
          }

# Identity
attribute 'member_id',
          :description => 'Member Id',
          :grouping => 'bom',
          :format => {
              :help => 'Unique Id of the Etcd member',
              :important => true,
              :category => '12.Identity',
              :order => 1
          }

recipe 'status', 'etcd status'
recipe 'start', 'etcd start'
recipe 'stop', 'etcd stop'
recipe 'restart', 'etcd restart'
