name             "Vagrant"
description      "Personal Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'path',
  :description => "Vagrantfile Path",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Directory path where Vagrantfile(s) should be created for each compute instance',
    :category => '1.Placement',
    :order => 1
  }

attribute 'console',
  :description => "Console",
  :default => "headless",
  :format => {
    :help => 'Virtual Box boot console',
    :category => '1.Placement',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['headless','headless'],['gui','gui']] }
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
  :default => '{"ubuntu-14.04":"https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box",
                "ubuntu-13.10":"https://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box",
                "ubuntu-13.04":"https://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box",
                "ubuntu-12.10":"https://cloud-images.ubuntu.com/vagrant/quantal/current/quantal-server-cloudimg-amd64-vagrant-disk1.box",
                "ubuntu-12.04":"http://files.vagrantup.com/precise64.box",
                "ubuntu-10.04":"http://files.vagrantup.com/lucid64.box",
                "centos-7.0":"http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.0_chef-provisionerless.box",
                "centos-6.5":"http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box",
                "centos-6.4":"http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.4_chef-provisionerless.box",
                "fedora-20":"http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_fedora-20_chef-provisionerless.box",
                "fedora-19":"http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_fedora-19_chef-provisionerless.box"}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '2.Mappings',
    :order => 2
  }

# networking
attribute 'bridge',
  :description => "Bridge",
  :default => "en0: Wi-Fi (AirPort)",
  :format => {
    :help => 'Virtual Box bridge interface for public network',
    :category => '3.Network',
    :order => 2
  }

attribute 'netmask',
  :description => "Netmask",
  :default => "255.255.255.0",
  :format => {
    :help => 'Virtual Box network mask for private network',
    :category => '3.Network',
    :order => 3
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
