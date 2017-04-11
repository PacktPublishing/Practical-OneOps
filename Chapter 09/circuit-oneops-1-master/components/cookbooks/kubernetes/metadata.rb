name              'Kubernetes'
maintainer        'OneOps'
license           'Apache 2.0'
description       'Configures and installs Kubernetes'
version           '0.0.1'


grouping 'default',
  :access => "global",
  :packages => [ 'base']

grouping 'cluster',
  :access => "global",
  :packages => [ 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

grouping 'service',
  :access => "global",
  :packages => [ 'service.container', 'service.orchestrator', 'mgmt.cloud.service', 'cloud.service' ]

# attrs for cloud service
attribute 'endpoint',
  :grouping => 'service',
  :description => "Endpoint",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Endpoint of kubernetes cluster',
    :category => '1.General',
    :order => 1
  }

attribute 'namespace',
  :grouping => 'service',
  :description => "Namespace",
  :default => "default",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Namespace',
    :category => '1.General',
    :order => 2
  }

attribute 'username',
  :grouping => 'service',
  :description => "Username",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Username',
    :category => '1.General',
    :order => 3
  }

attribute 'password',
  :grouping => 'service',
  :description => "Password",
  :encrypted => true,
  :format => {
    :help => 'Password',
    :category => '1.General',
    :order => 4
  }

attribute 'key',
  :grouping => 'service',
  :description => "Client Key",
  :encrypted => true,
  :format => {
    :help => 'Value passed to kubectl set-credentials --client-key',
    :category => '1.General',
    :order => 5
  }

  attribute 'cert',
  :grouping => 'service',
  :description => "Client Certificate",
  :encrypted => false,
  :format => {
    :help => 'Value passed to kubectl set-credentials --client-certificate',
    :category => '1.General',
    :order => 6
  }


# attrs for cluster
attribute 'version',
  :grouping => 'cluster',
  :description => "version",
  :default => "1.2.4",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Version',
    :category => '1.Shared',
    :order => 1
  }

attribute 'network',
  :grouping => 'cluster',
  :description => "Network Plugin",
  :default => "flannel",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Network Plugin - calico or flannel',
    :category => '1.Shared',
    :form => { 'field' => 'select', 'options_for_select' => [['flannel', 'flannel'],['calico', 'calico']] },
    :order => 2
  }

attribute 'control_plane_repo',
  :grouping => 'cluster',
  :description => "Control Plane Repo",
  :format => {
    :help => 'Interface',
    :category => '1.Shared',
    :order => 3
  }    
  
attribute 'api_port',
  :grouping => 'cluster',
  :description => "Insecure API port",
  :default => "8080",
  :required => "required",
  :format => {
    :important => true,
    :help => 'API Port',
    :category => '1.Master',
    :order => 3
  }

attribute 'api_port_secure',
  :grouping => 'cluster',
  :description => "Secure API port",
  :default => "6443",
  :required => "required",
  :format => {
    :important => true,
    :help => 'API Port',
    :category => '1.Master',
    :order => 3
  }

attribute 'log_level',
  :grouping => 'cluster',
  :description => "log_level",
  :default => "2",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Log Level - 0 to 4 (min to max) ',
    :category => '1.Master',
    :order => 4
  }

attribute 'service_addresses',
  :grouping => 'cluster',
  :description => "service address cidr",
  :default => "172.16.48.0/21",
  :required => "required",
  :format => {
    :important => true,
    :help => 'service address cidr',
    :category => '1.Master',
    :order => 5
  }

attribute 'pod_addresses',
  :grouping => 'cluster',
  :description => "pod address cidr",
  :default => "172.16.56.0/21",
  :required => "required",
  :format => {
    :important => true,
    :help => 'service address cidr',
    :category => '1.Master',
    :order => 6
  }
  
  
attribute 'controller_manager_args',
  :grouping => 'cluster',
  :description => "Controller Manager Args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :important => true,
    :help => 'Controller Manager Args',
    :category => '1.Master',
    :order => 7
  }

attribute 'scheduler_args',
  :grouping => 'cluster',
  :description => "Scheduler Args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'Scheduler Args',
    :category => '1.Master',
    :order => 8
  }

attribute 'api_args',
  :grouping => 'cluster',
  :description => "API Args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'API Args',
    :category => '1.Master',
    :order => 9
  }

attribute 'cluster_cloud_map',
  :grouping => 'cluster',
  :description => "Map of Clouds to Clusters",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'Map of Clouds to Clusters',
    :category => '1.Master',
    :order => 10
  }

attribute 'download_args',
  :grouping => 'cluster',
  :description => "Download Args",
  :data_type => "array",
  :default => '[]',
  :required => "required",
  :format => {
    :help => 'Download Args for wget eg) --limit-rate 128k',
    :category => '1.Master',
    :order => 11
  }


attribute 'security_enabled',
  :description => 'Enable SSL/TLS',
  :default => 'false',
  :format => {
      :help => 'Enable SSL/TLS',
      :category => '2.Authentication',
      :form => {:field => 'checkbox'},
      :order => 1
  }

attribute 'etcd_security_enabled',
  :description => 'Enable SSL/TLS to etcd',
  :default => 'false',
  :format => {
      :help => 'Enable SSL/TLS',
      :category => '2.Authentication',
      :form => {:field => 'checkbox'},
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 2
  }

attribute 'security_certificate',
  :description => 'Server Certificate',
  :data_type => 'text',
  :default => '',
  :format => {
      :help => 'Enter the certificate content to be used (Note: usually this is the content of the *.crt file).',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 3
  }

attribute 'security_key',
  :description => 'Server Key',
  :encrypted => true,
  :data_type => 'text',
  :default => '',
  :format => {
      :help => 'Enter the certificate key content (Note: usually this is the content of the *.key file).',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 4
  }

attribute 'security_ca_certificate',
  :description => 'CA Certificate',
  :data_type => 'text',
  :default => '',
  :format => {
      :help => 'Enter the CA certificate keys to be used to be used to trust certs signed only by this CA.',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 5
  }

attribute 'security_path',
  :description => 'Directory Path',
  :default => '/etc/kubernetes/ssl',
  :format => {
      :help => 'Directory path where the security files should be saved',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 6
  }

attribute 'basic_auth_users',
  :description => 'Basic Auth Users',
  :data_type => 'text',
  :encrypted => true,
  :default => '',
  :format => {
      :help => 'Kubernetes (basic) auth user file content. format: password,user,uid',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 7
  }

attribute 'token_auth_users',
  :description => 'Token Auth Users',
  :data_type => 'text',
  :encrypted => true,
  :default => '',
  :format => {
      :help => 'Kubernetes (token) auth user file content. format: token,user,uid,"group1,group2,group3"',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 8
  }

attribute 'auth_policy',
  :description => 'Auth Policy',
  :data_type => 'text',
  :default => '{"user":"admin"}
{"user":"kubecfg"}
{"user":"kubelet"}
{"user":"kube_proxy"}
{"user":"system:scheduler"}
{"user":"system:controller_manager"}
{"user":"system:logging"}
{"user":"system:monitoring"}
{"user":"system:serviceaccount:kube-system:default"}',
  :format => {
      :help => 'Kubernetes auth file content.',
      :category => '2.Authentication',
      :filter => {:all => {:visible => 'security_enabled:eq:true'}},
      :order => 9
  }


attribute 'kubelet_port',
  :grouping => 'cluster',
  :description => "kubelet bind port",
  :default => "10250",
  :required => "required",
  :format => {
    :help => 'The port for the Kubelet to serve on.',
    :category => '1.Worker',
    :order => 1
  }

attribute 'kubelet_args',
  :grouping => 'cluster',
  :description => "kubelet args",
  :data_type => "hash",
  :default => '{"cluster_dns":"172.16.63.254",
                "cluster_domain":"cluster.local",
                "pod-infra-container-image":"gcr.io/google_containers/pause:2.0"}',
  :required => "required",
  :format => {
    :help => 'Kubelet Args',
    :category => '1.Worker',
    :order => 1
  }

attribute 'proxy_args',
  :grouping => 'cluster',
  :description => "proxy args",
  :data_type => "hash",
  :default => '{}',
  :required => "required",
  :format => {
    :help => 'Proxy Args',
    :category => '1.Worker',
    :order => 1
  }

attribute 'interface',
  :grouping => 'cluster',
  :description => "Interface",
  :default => "eth0",
  :required => "required",
  :format => {
    :help => 'Interface',
    :category => '1.Worker',
    :order => 1
  }
  
