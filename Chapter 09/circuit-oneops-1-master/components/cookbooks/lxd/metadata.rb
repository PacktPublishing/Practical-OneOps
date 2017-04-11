name             "Lxd"
description      "Personal Compute Cloud Service with LXD"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'endpoint',
  :description => "API Endpoint",
  :required => "required",
  :default => "",
  :format => {
    :help => 'LXD server REST endpoint',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'client_cert',
  :description => "Client Cert",
  :data_type => "text",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Client Certificate (use ~/.config/lxd/client.crt or generate new and use lxc config trust add)',
    :category => '1.Authentication',
    :order => 2
}

attribute 'client_key',
  :description => "Client Key",
  :data_type => "text",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Client Key (use ~/.config/lxd/client.key or generate new and use lxc config trust add)',
    :category => '1.Authentication',
    :order => 3
}

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"default","S":"default","M":"default","L":"default","XL":"default" }',
  :format => {
    :help => 'Map of generic compute sizes to LXD profiles',
    :category => '2.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-16.04":"ubuntu",
                "centos-7.0":"centos"}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '2.Mappings',
    :order => 2
  }

attribute 'repo_map',
  :description => "OS Package Repositories keyed by OS Name",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of repositories by OS Type containing add commands - ex) yum-config-manager --add-repo repository_url or deb http://us.archive.ubuntu.com/ubuntu/ hardy main restricted ',
    :category => '4.Operating System',
    :order => 1
  }

attribute 'env_vars',
  :description => "System Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Environment variables - ex) http => http://yourproxy, https => https://yourhttpsproxy, etc',
    :category => '4.Operating System',
    :order => 3
  }

attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "ubuntu-16.04",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 4,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 16.04 (xenial)','ubuntu-16.04'],
      ['CentOS 7.0','centos-7.0']] }
  }
