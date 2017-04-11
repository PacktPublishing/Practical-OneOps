name             "Python"
description      "Installs/Configures Python"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]

# installation attributes
attribute 'install_type',
  :description => "Installation Type",
  :required => "required",
  :default => "repository",
  :format => {
    :category => '1.Source',
    :help => 'Select the type of installation - standard OS repository package or custom build from source code',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['Repository package','repository'],['Build from source','build']] }
  }  

attribute 'build_options',
  :description => "Build options",
  :data_type => "struct",
  :default => '{"srcdir":"/usr/local/src/python","version":"2.7.1","prefix":"/usr/local","configure":""}',
  :format => {
    :help => 'Specify ./configure options to be used when doing a build from source',
    :category => '1.Source',
    :order => 2
  }

attribute 'pip',
  :description => "PIP packages",
  :data_type => "array",
  :default => '["virtualenv"]',
  :format => {
    :category => '2.Modules',
    :order => 1,
    :help => 'Specify a list of PIP module packages to install'
  }

recipe "repair", "Repair Python"