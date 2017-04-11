name             'Playapp'
maintainer       'njin'
maintainer_email 'bathily@njin.fr'
license          'All rights reserved'
description      'Installs/Configures playapp'
version          '0.1.0'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']



attribute 'http_port',
  :description => "HttpPort",
  :required => "required",
  :default => '80',
  :format => {
    :help => 'Http Port for your Play application',
    :category => '1.Application Configuration',
    :order => 1
  }

attribute 'log_file',
  :description => "Log File",
  :format => {
    :help => 'Xml Log file for your application',
    :category => '1.Application Configuration',
    :order => 2
  }

attribute 'application_conf_file',
  :description => "play application conf file",
  :format => {
    :help => 'Your play application configuration file',
    :category => '1.Application Configuration',
    :order => 3
  }

attribute 'app_name',
:description => "Application name",
:required => "required",
:format => {
    :help => 'Your application name',
    :category => '1.Application Configuration',
    :order => 4
}

attribute 'app_location',
:description => "Application home",
:format => {
    :help => 'Your application home',
    :category => '1.Application Configuration',
    :order => 5
}

attribute 'app_secret',
:description => "Application Secret Key",
:encrypted => true,
:format => {
    :help => 'Your application secret key',
    :category => '1.Application Configuration',
    :order => 6
}

attribute 'app_opts',
  :description => "Java Startup parameters",
  :format => {
    :help => 'Java startup opts like Xmx',
    :category => '2.Startup Opts',
    :order => 1
  }

attribute 'app_dir',
:description => "app sub directory",
:format => {
    :help => 'sub directory under your zip root where your app is',
    :category => '2.Startup Opts',
    :order => 2
}

recipe "stop", "Stop the Application"
recipe "start", "Start the Application"
recipe "restart", "Restart the Application"
recipe "repair", "Repair the Application"
recipe "status", "Status of the Application"
