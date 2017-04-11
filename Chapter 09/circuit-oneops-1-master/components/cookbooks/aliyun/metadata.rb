name             "Aliyun"
description      "Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Copyright OneOps, All rights reserved."

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

attribute 'password',
  :description => "Initial Password to Login",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Initial password to login ECS with root',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'url',
  :description => "Aliyun URL",
  :required => "required",
  :default => "https://ecs.aliyuncs.com",
  :format => {
    :help => 'Aliyun URL for API to call',
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
      "XS":"ecs.t1.small"
    }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
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
                "redhat-6.5":"",
                "redhat-6.4":"",
                "redhat-6.2":"",
                "redhat-5.9":"",
                "centos-7.0":"",
                "centos-6.5":"",
                "centos-6.4":"",
                "fedora-20":"",
                "fedora-19":""}',
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
  :default => '{"rubygems":"https://ruby.taobao.org"}',
  :format => {
    :help => 'Environment variables - ex) http => http://yourproxy, https => https://yourhttpsproxy, etc',
    :category => '4.Operating System',
    :order => 2
  }

# operating system
attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "centos-7.0",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 14.04.1 (trusty)','ubuntu-14.04'],
      ['Ubuntu 13.10 (saucy)','ubuntu-13.10'],
      ['Ubuntu 13.04 (raring)','ubuntu-13.04'],
      ['Ubuntu 12.10 (quantal)','ubuntu-12.10'],
      ['Ubuntu 12.04.5 (precise)','ubuntu-12.04'],
      ['Ubuntu 10.04.4 (lucid)','ubuntu-10.04'],
      ['RedHat 7.0','redhat-7.0'],
      ['RedHat 6.5','redhat-6.5'],
      ['RedHat 6.4','redhat-6.4'],
      ['RedHat 6.2','redhat-6.2'],
      ['RedHat 5.9','redhat-5.9'],
      ['CentOS 7.0','centos-7.0'],
      ['CentOS 6.5','centos-6.5'],
      ['CentOS 6.4','centos-6.4'],
      ['Fedora 20','fedora-20'],
      ['Fedora 19','fedora-19']] }
  }

attribute 'internetchargetype',
  :description => "Internet Charge Type",
  :required => "required",
  :default => "PayByBandwidth",
  :format => {
    :help => 'How to pay for internet bandwidth, PayByBandwidth or PayByTraffic - see provider open-api documentation for details',
    :category => '5.Internet Charge',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Pay By Bandwidth','PayByBandwidth'],
      ['Pay By Traffic', 'PayByTraffic']] }
  }

attribute 'internetmaxbandwidthin',
  :description => "Internet Max Bandwidth In (Mbps)",
  :required => "required",
  :default => "200",
  :format => {
    :help => 'Maximum In-bound Bandwidth in Mbps(Mega bit per second), range from 1 to 200 - see provider open-api documentation for details',
    :category => '5.Internet Charge',
    :order => 2
  }

attribute 'internetmaxbandwidthout',
  :description => "Internet Max Bandwidth Out (Mbps)",
  :required => "required",
  :default => "1",
  :format => {
    :help => 'Maximum Out-bound Bandwidth in Mbps(Mega bit per second), range from 1 to 100 - see provider open-api documentation for details',
    :category => '5.Internet Charge',
    :order => 3
  }
