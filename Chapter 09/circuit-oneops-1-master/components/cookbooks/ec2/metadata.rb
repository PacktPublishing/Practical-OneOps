name             "Ec2"
description      "Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'key',
  :description => "Access Key",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Access key from the provider security credentials page',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'secret',
  :description => "Secret Key",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Secret key from the provider security credentials page',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'region',
  :description => "Region",
  :default => "",
  :format => {
    :help => 'Region Name',
    :category => '2.Placement',
    :order => 1
  }

attribute 'availability_zones',
  :description => "Availability Zones",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Availability Zones - Singles will round robin, Redundant will use platform id',
    :category => '2.Placement',
    :order => 2
  }  
  
attribute 'subnet',
  :description => "Subnet Name",
  :default => "",
  :format => {
    :help => 'Subnet Name is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 3
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{
      "XS":"t2.micro",
      "S":"t2.small",
      "M":"t2.medium",
      "L":"m4.large",
      "XL":"m4.xlarge",
      "XXL":"m4.2xlarge",
      "4XL":"m4.4xlarge",
      "S-CPU":"",
      "M-CPU":"c4.large",
      "L-CPU":"c4.xlarge",
      "XL-CPU":"c4.2xlarge",
      "XXL-CPU":"c4.4xlarge",
      "4XL-CPU":"c4.8xlarge",
      "S-MEM":"",
      "M-MEM":"",
      "L-MEM":"r3.large",
      "XL-MEM":"r3.xlarge",
      "XXL-MEM":"r3.2xlarge",
      "4XL-MEM":"r3.4xlarge",
      "S-IO":"",
      "M-IO":"",
      "L-IO":"",
      "XL-IO":"i2.xlarge",
      "XXL-IO":"i2.2xlarge",
      "4XL-IO":"i2.4xlarge"
    }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-16.04":"",
                "centos-7.2":"",
                "fedora-24":""}',
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
    :order => 2
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
  :default => "centos-7.2",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 16.04 (xenial)','ubuntu-16.04'],
      ['CentOS 7.2','centos-7.2'],
      ['Fedora 24','fedora-24'] ] }
  }
