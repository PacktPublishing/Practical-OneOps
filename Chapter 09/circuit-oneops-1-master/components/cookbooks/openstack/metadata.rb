name             "Openstack"
description      "Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.compute', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'endpoint',
  :description => "API Endpoint",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Endpoint URL',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'tenant',
  :description => "Tenant",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Tenant Name',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Username',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Password',
    :category => '1.Authentication',
    :order => 4
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
    :help => 'Availability Zones - Singles will round robin, Redundant will use index',
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

attribute 'enabled_networks',
  :description => "Enabled Networks",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Enabled Network List is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 4
  }  
  
attribute 'public_network_type',
  :description => "Public Network Type",
  :default => "flat",
  :format => {
    :help => 'Public network type. Flat for standard openstack. Floating for needing a floating ip to be accessable.',
    :category => '2.Placement',
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Flat','flat'],
      ['Floating','floatingip']] },
    :order => 4
  }

attribute 'public_subnet',
  :description => "Public Subnet Name",
  :default => "",
  :format => {
    :help => 'Public Subnet Name is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 5
  }



attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"1","S":"2","M":"3","L":"4","XL":"5","XXL":"12","3XL":"11" }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }
  
attribute 'flavormap',
  :description => "Flavor Map",
  :data_type => "hash",
  :default => '{}',
  :format => {
     :help => 'Map of generic flavors to number of vcpus/ram/ephermal disk size',
     :category => '3.Mappings',
     :order => 2
  }  

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-14.04":"",
                "ubuntu-13.10":"",
                "ubuntu-13.04":"",
                "ubuntu-12.10":"",
                "ubuntu-12.04":"",
                "ubuntu-10.04":"",
                "redhat-7.0":"",
		"redhat-6.6":"",
                "redhat-6.5":"",
                "redhat-6.4":"",
                "redhat-6.2":"",
                "redhat-5.9":"",
                "centos-7.0":"",
		"centos-6.6":"",
                "centos-6.5":"",
                "centos-6.4":"",
                "fedora-20":"",
                "fedora-19":""}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
    :order => 3
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
    :order => 3
  }



# operating system
attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "centos-6.4",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 4,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 14.04.1 (trusty)','ubuntu-14.04'],
      ['Ubuntu 13.10 (saucy)','ubuntu-13.10'],
      ['Ubuntu 13.04 (raring)','ubuntu-13.04'],
      ['Ubuntu 12.10 (quantal)','ubuntu-12.10'],
      ['Ubuntu 12.04.5 (precise)','ubuntu-12.04'],
      ['Ubuntu 10.04.4 (lucid)','ubuntu-10.04'],
      ['RedHat 7.0','redhat-7.0'],
      ['RedHat 6.6','redhat-6.6'],
      ['RedHat 6.5','redhat-6.5'],
      ['RedHat 6.4','redhat-6.4'],
      ['RedHat 6.2','redhat-6.2'],
      ['RedHat 5.9','redhat-5.9'],
      ['CentOS 7.0','centos-7.0'],
      ['CentOS 6.6','centos-6.6'],
      ['CentOS 6.5','centos-6.5'],
      ['CentOS 6.4','centos-6.4'],
      ['Fedora 20','fedora-20'],
      ['Fedora 19','fedora-19']] }
  }

attribute 'initial_user',
  :description => "Initial UserName",
  :default => '',
  :format => {
  :help => 'Initial UserName to use for computes',
  :category => '4.Operating System',
  :order => 5
  }

# limits
attribute 'max_instances',
  :description => "Max Total Instances",
  :default => '',
  :format => {
    :help => 'Max total instances for tenant',
    :category => '5.Quota',
    :order => 1,
    :editable => false
  }

attribute 'max_cores',
  :description => "Max Total Cores",
  :default => '',
  :format => {
    :help => 'Max total cores for tenant',
    :category => '5.Quota',
    :order => 2,
    :editable => false
  }

attribute 'max_ram',
  :description => "Max Total RAM Size",
  :default => '',
  :format => {
    :help => 'Max total RAM size for tenant',
    :category => '5.Quota',
    :order => 3,
    :editable => false
  }

attribute 'max_keypairs',
  :description => "Max Total Keypairs",
  :default => '',
  :format => {
    :help => 'Max total keypairs for tenant',
    :category => '5.Quota',
    :order => 4,
    :editable => false
  }

attribute 'max_secgroups',
  :description => "Max Total Security Groups",
  :default => '',
  :format => {
    :help => 'Max total security groups for tenant',
    :category => '5.Quota',
    :order => 5,
    :editable => false
  }

recipe "validate", "Validate Service Configuration"
recipe "status", "Check Service Status"
