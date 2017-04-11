name             "Softlayer"
description      "Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Username',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'apikey',
  :description => "API Key",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Key',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'datacenter',
  :description => "Datacenter",
  :default => "dal10",
  :format => {
    :help => 'Datacenter Name',
    :category => '2.Placement',
    :order => 1
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"m1.tiny","S":"m1.small","M":"m1.medium","L":"m1.large","XL":"m1.xlarge" }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-16.04":"d4bd5bfb-4b7c-4fb0-b742-ed548d8bd1e7",
                "ubuntu-14.04":"ad42bfe1-7c8d-4784-8559-4ff9d2648cdb",
                "ubuntu-12.04":"f5b8a615-84ea-4527-96fa-be07b453c591",
                "redhat-6":"cc30a0a6-b0f1-4db1-82d4-215977aba61d",
                "redhat-5":"185aabae-0dca-477e-8f74-1a649bda45fa",
                "centos-7":"ebf2c369-19e4-4f90-b43d-2be32ae4e4b9",
                "centos-6":"54f4ed9f-f7e6-4fe6-8b54-3a7faacd82b3",
                "centos-5":"29073a7a-2fac-405c-b59f-4de8ad6e4945",
                "fedora-15":"53bd113b-29ab-4f4b-83a2-514d56174dfe"}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
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
    :order => 2
  }

# operating system
attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "centos-7",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
        ['Ubuntu 16.04 (trusty)','ubuntu-16.04'],
        ['Ubuntu 14.04 (trusty)','ubuntu-14.04'],
        ['Ubuntu 12.04 (trusty)','ubuntu-12.04'],
        ['RedHat 6.x','redhat-6'],
        ['RedHat 5.x','redhat-5'],
        ['CentOS 7.0','centos-7'],
        ['CentOS 6.0','centos-6'],
        ['CentOS 5.0','centos-5'],
        ['Fedora 15','fedora-15']
      ]
    }
  }
