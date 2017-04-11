name             "Nginx"
description      "Installs/Configures nginx"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => "1.0.5",
  :format => {
    :help => 'Version of Nginx server',
    :category => '1.Source',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['1.0.5','1.0.5']] }, 
    :pattern =>"[0-9\.]+"
  }

attribute 'user',
  :description => "User",
  :format => {
    :help => 'System user that Nginx server process should run as',
    :category => '1.Global',
    :order => 2
  }

attribute 'keepalive',
  :description => "Keep Alive",
  :default => 'on',
  :format => {
    :help => 'Enables HTTP persistent connections',
    :category => '1.Global',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [['On','on'],['Off','off']] }
  }

attribute 'keepalive_timeout',
  :description => "Keep Alive Timeout",
  :default => '65',
  :format => {
    :help => 'Timeout for persistent connections',
    :category => '1.Global',
    :order => 4,
    :pattern => "[0-9]+"
  }

# performance
attribute 'worker_processes',
  :description => "Worker Processes",
  :default => '4',
  :format => {
    :category => '2.Performance',
    :order => 1
  }

attribute 'events',
  :description => "Events Module",
  :data_type => "hash",
  :default => '{"worker_connections":2048}',
  :format => {
    :help => 'These directive control how Nginx deals with connections',
    :category => '2.Performance',
    :order => 2
  }
  
# upstream proxies
attribute 'upstream',
  :description => "Upstream Definitions",
  :data_type => "text",
  :default => "",
  :format => {
    :category => '3.Upstream',
    :order => 1,
    :help => 'Provide full upstream definitions (Note: you can put more then one definition here)'
  }

# extra
attribute 'extra',
  :description => "Custom Server Configuration",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter additional Nginx directives to be included in the server configuration',
    :category => '4.Custom',
    :order => 1
  }
  

recipe "status", "Nginx Status"
recipe "start", "Start Nginx"
recipe "stop", "Stop Nginx"
recipe "restart", "Restart Nginx"
recipe "repair", "Repair Nginx"
