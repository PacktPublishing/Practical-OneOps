name             "Docker"
description      "Personal Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.compute', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'path',
  :description => "Dockerfile Path",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Directory path where Dockerfile(s) should be created for each compute instance',
    :category => '1.Placement',
    :order => 1
  }

attribute 'docker_env',
  :description => "Docker Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Set docker environment variables when running docker client (example: DOCKER_HOST, DOCKER_MACHINE_NAME, DOCKER_CERT_PATH, DOCKER_TLS_VERIFY)',
    :category => '1.Placement',
    :order => 2
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{ "XS":"1x512","S":"1x1024","M":"1x2048","M-CPU":"2x2048","L":"2x4096","XL":"2x8196","XL-CPU":"4x8196" }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '2.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-14.04":"ubuntu:14.04",
                "ubuntu-13.10":"ubuntu:13.10",
                "ubuntu-13.04":"ubuntu:13.04",
                "ubuntu-12.10":"ubuntu:12.10",
                "ubuntu-12.04":"ubuntu:12.04",
                "ubuntu-10.04":"ubuntu:10.04",
                "centos-7.0":"centos:centos7",
                "centos-6.5":"centos:centos6",
                "opensuse-13.1":"opensuse:13.1",
                "fedora-20":"fedora:20",
                "fedora-19":"fedora:19"}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '2.Mappings',
    :order => 2
  }

attribute 'network',
  :description => "Network",
  :default => "hostonly",
  :format => {
    :help => 'Virtual Box network type configuration',
    :category => '3.Network',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['hostonly','hostonly'],['bridged','bridged']] }
  }

attribute 'host_ip',
  :description => "Host IP Address",
  :default => "",
  :format => {
    :help => 'The IP address of the docker host. You can leave it blank if using boot2docker.',
    :category => '3.Network',
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
  :default => "centos-6.5",
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
      ['RedHat 6.5','redhat-6.5'],
      ['RedHat 6.4','redhat-6.4'],
      ['RedHat 6.2','redhat-6.2'],
      ['RedHat 5.9','redhat-5.9'],
      ['CentOS 7.0','centos-7.0'],
      ['CentOS 6.5','centos-6.5'],
      ['CentOS 6.4','centos-6.4'],
      ['OpenSuSE 13.1','opensuse-13.1'],
      ['Fedora 20','fedora-20'],
      ['Fedora 19','fedora-19']] }
  }
