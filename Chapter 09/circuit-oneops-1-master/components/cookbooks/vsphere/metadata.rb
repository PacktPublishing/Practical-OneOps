name             'Vsphere'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          "Copyright OneOps, All rights reserved."
description      'Installs/Configures vsphere'
version          '0.1'
depends					 "compute"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service'],
  :namespace => true


attribute 'endpoint',
  :description => "vCenter Endpoint",
  :required => "required",
  :default => "",
  :format => {
    :help => 'vCenter Endpoint URL',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'vCenter Username',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'vCenter Password',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'vsphere_pubkey',
  :description => "vCenter Public Key",
  :required => "required",
  :default => "",
  :format => {
    :help => 'vCenter Public Key',
    :category => '1.Authentication',
    :order => 4
  }

attribute 'datacenter',
  :description => "Data Center",
  :required => "required",
  :default => "DistributionCenter1",
  :format => {
    :help => 'Data Center',
    :category => '2.Configuration',
    :order => 1
  }

attribute 'cluster',
  :description => "Cluster",
  :required => "required",
  :default => "Cluster1",
  :format => {
    :help => 'Data Center Cluster',
    :category => '2.Configuration',
    :order => 2
  }

attribute 'datastore',
  :description => "Datastore",
  :required => "required",
  :default => "datastore1",
  :format => {
    :help => 'Data Center Datastore',
    :category => '2.Configuration',
    :order => 3
  }

attribute 'resource_pool',
  :description => "Resource Pool",
  :required => "required",
  :default => "Resources",
  :format => {
    :help => 'Use to apply resource restrictions',
    :category => '2.Configuration',
    :order => 4
  }

attribute 'network',
  :description => "Network Name",
  :required => "required",
  :default => "VM Public Network",
  :format => {
    :help => 'Compute will be assigned to this network',
    :category => '2.Configuration',
    :order => 5
  }

attribute 'bandwidth_throttle_rate',
  :description => "Throttle Bandwidth KBps",
  :default => '',
  :format => {
    :help => 'To throttle bandwidth enter data transfer rate in KiloBytes (integer) per second.',
    :category => '2.Configuration',
    :order => 6
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"1x512x0","S":"1x1024x10","M":"1x2048x20","M-CPU":"2x2048x20","L":"2x4096x30","XL":"2x8196x40","XL-CPU":"4x8196x40" }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }

  attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"centos-7.2":""}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
    :order => 2
  }

attribute 'repo_map',
  :description => "OS Package Repositories keyed by OS Name",
  :data_type => "hash",
  :default => '{"centos-7.2":""}',
  :format => {
    :help => 'Map of repositories by OS Type containing add commands - ex) yum-config-manager --add-repo repository_url or deb http://us.archive.ubuntu.com/ubuntu/ hardy main restricted ',
    :category => '4.Operating System',
    :order => 1
  }

attribute 'env_vars',
:description => "System Environment Variables",
:data_type => "hash",
:default => '{"rubygems":"","rubygemsbkp":"","misc":""}',
:format => {
  :help => 'Environment variables - ex) http => http://yourproxy, https => https://yourhttpsproxy, etc',
  :category => '4.Operating System',
  :order => 2
}

attribute 'ostype',
:description => "OS Type",
:required => "required",
:default => "centos-7.2",
:format => {
  :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
  :category => '4.Operating System',
  :order => 3,
  :form => { 'field' => 'select', 'options_for_select' => [
  ['CentOS 7.2','centos-7.2']]
  }
}

recipe "validate_connection", "Validate Service Configuration"
