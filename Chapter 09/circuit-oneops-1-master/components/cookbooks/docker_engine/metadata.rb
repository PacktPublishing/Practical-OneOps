name              'Docker_engine'
description       'A portable, lightweight application runtime and packaging tool.'
version           '1.0.0'
maintainer        'OneOps'
maintainer_email  'support@oneops.com'
license           'Apache License, Version 2.0'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '1.11.2',
          :format => {
              :important => true,
              :help => 'Docker engine version',
              :category => '1.Binary',
              :order => 1,
              :form => {:field => 'select', :options_for_select => [['1.9.1', '1.9.1'], ['1.10.2', '1.10.2'], ['1.11.2', '1.11.2'], ['1.12.6', '1.12.6']]}
          }

attribute 'repo',
          :description => 'Repository',
          :default => '',
          :format => {
              :important => true,
              :help => "Docker release package repository. Uses official repo (https://dockerproject.org) if it's empty.",
              :category => '1.Binary',
              :order => 2
          }

attribute 'root',
          :description => 'Docker Root',
          :required => 'required',
          :default => '/var/lib/docker',
          :format => {
              :important => true,
              :help => 'Root of the Docker runtime',
              :category => '2.Docker Options',
              :order => 1
          }

attribute 'daemon_options',
          :description => 'Daemon Options',
          :data_type => 'array',
          :default => '["--debug=false","--selinux-enabled=false"]',
          :format => {
              :important => true,
              :category => '2.Docker Options',
              :help => 'Options for docker engine daemon. Check "docker daemon --help" for all the options.',
              :order => 2
          }

attribute 'disable_legacy_registry',
          :description => 'Disable Legacy Registry',
          :default => 'false',
          :format => {
              :important => true,
              :category => '3.Docker Registry',
              :help => 'Do not contact legacy registries',
              :form => {:field => 'checkbox'},
              :order => 1
          }

attribute 'insecure_registry',
          :description => 'Insecure Registries',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '3.Docker Registry',
              :help => 'Enable insecure registry communication.',
              :order => 2
          }

attribute 'registry_mirror',
          :description => 'Registry Mirrors',
          :data_type => 'array',
          :default => '[]',
          :format => {
              :category => '3.Docker Registry',
              :help => 'Preferred Docker registry mirror.',
              :order => 3
          }


attribute 'tlsverify',
          :description => 'TLS Verify',
          :default => 'false',
          :format => {
              :help => 'Use TLS and verify the remote.',
              :category => '4.TLS',
              :form => {:field => 'checkbox'},
              :order => 1
          }

attribute 'tlscacert',
          :description => 'CA Certificate',
          :data_type => 'text',
          :default => '',
          :format => {
              :help => 'Trust certs signed only by this CA.',
              :category => '4.TLS',
              :filter => {:all => {:visible => 'tlsverify:eq:true'}},
              :order => 2,
              :editable => true
          }

attribute 'tlscert',
          :description => 'Certificate',
          :data_type => 'text',
          :default => '',
          :format => {
              :help => 'TLS certificate.',
              :category => '4.TLS',
              :filter => {:all => {:visible => 'tlsverify:eq:true'}},
              :order => 3,
              :editable => true
          }

attribute 'tlskey',
          :description => 'Cert Key',
          :data_type => 'text',
          :default => '',
          :format => {
              :help => 'TLS key.',
              :category => '4.TLS',
              :filter => {:all => {:visible => 'tlsverify:eq:true'}},
              :order => 4,
              :editable => true
          }

attribute 'env_vars',
          :description => 'Environment variables',
          :data_type => 'hash',
          :default => '{}',
          :format => {
              :category => '5.Env Vars',
              :help => 'Environment variables for docker engine. E.g. To use HTTP proxy, adds the "HTTP_PROXY" and "NO_PROXY" env vars.',
              :order => 1
          }

attribute 'limit_directives',
          :description => 'Limit directives',
          :data_type => 'hash',
          :default => '{"LimitNOFILE" : "1048576", "LimitNPROC" : "1048576", "LimitCORE" : "infinity"}',
          :format => {
              :category => '6.Limits',
              :help => 'Systemd limit directives for docker engine. Use the string "infinity" to configure no limit on a specific resource.',
              :order => 1
          }
          
          
attribute 'network',
          :description => 'Network',
          :default => 'none',
          :format => {
            :category => '7.Network',
            :help => 'Network Overlay/CNI',
            :form => {
              :field => 'select',
              :options_for_select => [['none', 'none'], ['flannel', 'flannel'], ['calico', 'calico']]
            },
            :order => 1
          }          

attribute 'network_cidr',
          :description => 'Network CIDR',
          :default => '11.11.0.0/16',
          :format => {
            :category => '7.Network',
            :help => 'Network CIDR',
            :form => {
              :filter => {:all => {:visible => 'network:ne:none'}},
            },
            :order => 2
          }

attribute 'flannel_security_enabled',
          :description => 'Flannel Etcd TLS Enabled',
          :default => 'false',
          :format => {
            :category => '7.Flannel',
            :help => 'Flannel Etcd TLS Enabled',
            :form => {
              :filter => {:all => {:visible => 'network:eq:flannel'}},
            },
            :order => 3
          }                       
                    
attribute 'flannel_security_cacert',
          :description => 'Flannel Etcd CA Cert',
          :default => '',
          :format => {
            :category => '7.Flannel',
            :help => 'Flannel Etcd CA Cert',
            :form => {
              :filter => {:all => {:visible => 'flannel_security_enabled:eq:true'}},
            },
            :order => 4
          }

attribute 'flannel_security_cert',
          :description => 'Flannel Etcd Cert',
          :default => '',
          :format => {
            :category => '7.Flannel',
            :help => 'Flannel Etcd CA Cert',
            :form => {
              :filter => {:all => {:visible => 'flannel_security_enabled:eq:true'}},
            },
            :order => 5
          }
           
attribute 'flannel_security_key',
          :description => 'Flannel Etcd Key',
          :default => '',
          :encrypted => true,
          :format => {
            :category => '7.Flannel',
            :help => 'Flannel Etcd CA Cert',
            :form => {
              :filter => {:all => {:visible => 'flannel_security_enabled:eq:true'}},
            },
            :order => 6
          }
          
recipe 'status', 'Docker engine Status'
recipe 'start', 'Start Docker engine'
recipe 'stop', 'Stop Docker engine'
recipe 'restart', 'Restart Docker engine'
