name             "Ruby"
description      "Installs/Configures Ruby"
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
    :form => { 'field' => 'select', 'options_for_select' => [['Repository package','repository'],['RVM','rvm']] }
  }

attribute 'version',
  :description => "Version",
  :default => "1.9.3",
  :format => {
    :important => true,
    :help => 'Version of Ruby',
    :category => '1.Source',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['1.9.3','1.9.3-p547'],['2.0.0','2.0.0-p576'],['2.1.0','2.1.0'],['2.1.2','2.1.2'],['2.1.3','2.1.3'],['2.2.1','2.2.1'],['2.2.6','2.2.6'],['2.3.3','2.3.3']] } ,
    :pattern => "[0-9\.]+",
    :filter => {"all" => {"visible" => "install_type:eq:rvm"}}
  }

attribute 'binary',
  :description => "Ruby Binary Location",
  :default => "",
  :format => {
    :help => 'Specify the URL location of the ruby package. Leave empty if using the public binary repositories from rvm.io or if using the mirror service with private replicas of those repositories. Use only if the binary is in a custom location. Example: https://rvm.io/binaries/centos/6/x86_64/ruby-2.1.0.tar.bz2',
    :category => '1.Source',
    :order => 3,
    :filter => {"all" => {"visible" => "install_type:eq:rvm"}}
  }

attribute 'gems',
  :description => "Gems",
  :data_type => "hash",
  :default => '{ "bundler":"" }',
  :format => {
    :category => '2.Gems',
    :order => 1,
    :help => 'Specify a list of gems to install (Note: second field is an optional version parameter)'
  }

recipe "repair", "Repair Ruby"
