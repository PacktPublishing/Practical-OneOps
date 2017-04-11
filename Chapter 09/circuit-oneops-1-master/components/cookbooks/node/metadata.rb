name             "Node"
description      "Installs/Configures Node.js"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"


recipe "status", "Node Status"
recipe "start", "Start Node application"
recipe "stop", "Stop Node application"
recipe "restart", "Restart Node application"


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]

# using binary only install until os repos get updated more frequently 
# currently latest centos has 0.10, while binary has 4.4 is stable, 6.2 current
attribute 'install_method',
  :description => "Install via (package or binary)",
  :default => "binary",
  :format => {
    :category => '1.Global',
    :order => 1,
    :filter => {'all' => {'visible' => 'install_method:eq:onlybinaryrightnow'}},    
    :help => 'Installation method',
    :form => {'field' => 'select', 'options_for_select' => [['binary', 'binary'], ['package', 'package']]}
  }

attribute 'version',
  :description => "Version",
  :default => "4.4.7",
  :format => {
    :category => '1.Global',
    :order => 2,
    :help => 'Version of Node.js'
  }

attribute 'src_url',
  :description => "Location of nodejs binary",
  :format => {
    :category => '1.Global',
    :order => 3,
    :help => 'Specify a list of node source ',
    :filter => {'all' => {'visible' => 'install_method:eq:binary'}}
  }

attribute 'dir',
  :description => "Install location",
  :format => {
    :category => '1.Global',
    :order => 4,
    :help => 'Node install location'
  }

attribute 'checksum_linux_x64',
  :description => "Checksum",
  :format => {
    :category => '1.Global',
    :order => 5,
    :help => 'Check Sum of the binary',
    :filter => {'all' => {'visible' => 'install_method:eq:binary'}}
  }

attribute 'npm_src_url',
  :description => "NPM source URL",
  :format => {
    :category => '1.Global',
    :order => 6,
    :help => 'NPM resgistry URL',
    :filter => {'all' => {'visible' => 'install_method:eq:binary'}}
  }

attribute 'npm',
  :description => "NPM version",
  :format => {
    :category => '1.Global',
    :order => 7,
    :default => "3.10.3",
    :help => 'NPM version'
  }

recipe "repair", "Repair Nodejs"
