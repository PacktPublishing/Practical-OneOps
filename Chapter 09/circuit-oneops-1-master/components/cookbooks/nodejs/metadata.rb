name             "Nodejs"
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

attribute 'install_method',
  :description => "Install via (source or package or binary)",
  :default => "binary",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'Installation method'  
  }

attribute 'version',
  :description => "Version",
  :default => "0.10.17",
  :format => {
    :category => '1.Global',
    :order => 2,
    :help => 'Version of Node.js' , 
    :form => { 'field' => 'select', 'options_for_select' => [['0.10.17','0.10.17'],['0.10.26','0.10.26'],['0.10.33','0.10.33'],['0.10.35','0.10.35'],['0.10.36','0.10.36'],['0.10.39','0.10.39'],['0.12.4','0.12.4']] }
  }

attribute 'src_url',
  :description => "Location of binary",
  :format => {
    :category => '1.Global',
    :order => 3,
    :help => 'Specify a list of node source '
  }

attribute 'checksum_linux_x64',
  :description => "Checksum",
  :format => {
    :category => '1.Global',
    :order => 4,
    :help => 'Check Sum of the binary'   
  }
attribute 'dir',
  :description => "Install location",
  :format => {
    :category => '1.Global',
    :order => 5,
    :help => 'Node install location'
  }

attribute 'as_user',
  :description => "Run as User",
  :format => {
    :category => '1.Global',
    :order => 6,
    :help => 'Run node as '
  }

attribute 'options',
  :description => "Start options",
  
  :format => {
    :category => '1.Global',
    :order => 7,
    :help => 'Start node options'
  }  

attribute 'script_location',
  :description => "Server start up script",
  :format => {
    :category => '1.Global',
    :order => 8,
    :help => 'Start node options'
  }  

attribute 'log_file',
  :description => "Log file location",
  :default => "/log/nodejs/app.js.log",
  :format => {
    :category => '1.Global',
    :order => 9,
    :help => 'location of log file'
  }  
attribute 'server_root',
  :description => "Server location",
  :default =>"/app/tempo/current/standalone",
  :format => {
    :category => '1.Global',
    :order => 11,
    :help => 'Directory where you want the server to be run from '
  }  

attribute 'name',
  :description => "Name of the artifact",
  :format => {
    :category => '1.Global',
    :order => 10,
    :help => 'Name of the app (artifactid)'
  }  


recipe "repair", "Repair Nodejs"
