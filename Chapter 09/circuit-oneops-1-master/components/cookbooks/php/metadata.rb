name             "Php"
description      "Installs/Configures PHP"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom' ]

# installation attributes

attribute 'version',
  :description => 'Version',
  :required => 'required',
  :default => '5.3.3',
  :format => {
    :important => true,
    :help => 'PHP Version',
    :category => '1.Source',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['default', 'default'], ['5.5.30', '5.5.30'], ['5.5.37', '5.5.37'], ['5.5.38', '5.5.38']]}
    }

attribute 'install_type',
  :description => "Installation Type",
  :required => "required",
  :default => "repository",
  :format => {
    :category => '1.Source',
    :help => 'Select the type of installation - standard OS repository package or custom build from source code',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['Repository package','repository'],['Build from source','build']] }
  }  

attribute 'build_options',
  :description => "Build options",
  :data_type => "struct",
  :default => '{"srcdir":"/usr/local/src/php","version":"PHP_5_3_10","prefix":"/usr/local/php","configure":""}',
  :format => {
    :help => 'Specify ./configure options to be used when doing a build from source',
    :category => '1.Source',
    :order => 3
  }
 
# fcgi 
attribute 'fcgi',
  :description => "Fast CGI",
  :default => 'false',
  :format => { 
    :category => '2.Fast CGI', 
    :order => 1, 
    :help => 'Enable fast CGI mode',
    :form => { 'field' => 'checkbox' } 
  }
    
attribute 'port',
  :description => "Fast CGI Port",
  :default => "9000",
  :format => { 
    :category => '2.Fast CGI', 
    :order => 1, 
    :help => 'Set the port that Fast CGI will listen on',
    :form => { 'field' => 'checkbox' },
    :pattern => "[0-9\.]+"
  }

recipe "repair", "Repair"
