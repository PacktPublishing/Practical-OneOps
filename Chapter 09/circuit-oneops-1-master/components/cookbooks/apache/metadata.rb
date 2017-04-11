name             "Apache"
description      "Installs/Configures Apache"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

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
  :default => '{"srcdir":"/usr/local/src/apache","version":"2.2.21","prefix":"/usr/local/apache","configure":""}',
  :format => {
    :help => 'Specify ./configure options to be used when doing a build from source',
    :category => '1.Source',
    :order => 2
  }

# # global attributes
attribute 'contact',
  :description => "Server Admin",
  :default => "www-admin@example.com",
  :format => {
    :help => 'The ServerAdmin sets the contact address that the server includes in any error messages it returns to the client',
    :category => '2.Global',
    :order => 1
  }

attribute 'ports',
  :description => "Listen Ports",
  :data_type => "array",
  :required => "required",
  :default => '["80","443"]',
  :format => {
    :help => 'TCP ports apache should listen on',
    :category => '2.Global',
    :order => 2
  }

attribute 'user',
  :description => "User",
  :format => {
    :help => 'Enter the username that apache should run as',
    :category => '2.Global',
    :order => 3
  }

attribute 'request_timeout',
  :description => "Request Timeout",
  :default => '300',
  :format => {
    :help => 'Amount of time the server will wait for certain events before failing a request',
    :category => '2.Global',
    :order => 4
  }

attribute 'keepalive',
  :description => "Keep Alive",
  :default => 'On',
  :format => {
    :help => 'Enables HTTP persistent connections',
    :category => '2.Global',
    :order => 5,
    :form => { 'field' => 'select', 'options_for_select' => [["On","On"],["Off","Off"]] }
  }

# security
attribute 'signature',
  :description => "Server Signature",
  :default => 'On',
  :format => {
    :help => 'This directive allows the configuration of a trailing footer line under server-generated documents (error messages, mod_proxy ftp directory listings, mod_info output, ...)',
    :category => '3.Security',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['On','On'],['Off','Off'],['Email','Email']] }
  }

attribute 'tokens',
  :description => "Server Tokens",
  :default => "Prod",
  :format => {
    :help => 'This directive controls whether Server response header field which is sent back to clients includes a description of the generic OS-type of the server as well as information about compiled-in modules.',
    :category => '3.Security',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['Major','Major'],['Minor','Minor'],['Minimal','Minimal'],['Prod','Prod'],['OS','OS'],['Full','Full']] }
  }

attribute 'traceenable',
  :description => "Enable TRACE HTTP Method",
  :default => "On",
  :format => {
    :help => 'This directive enables/disables the TRACE HTTP method. Enabling TRACE is considered a security vulnarability and should only be enabled for troubleshooting or in pre-production environments.',
    :category => '3.Security',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [['On','On'],['Off','Off'],['extended','extended']] }
  }

attribute 'enableetags',
  :description => "Enable ETags",
  :default => "On",
  :format => {
    :help => 'This directive enables/disables the ETag (Entity tags). Enabling ETags is considered a security vulnarability and should only be enabled for troubleshooting or in pre-production environments.',
    :category => '3.Security',
    :order => 4,
    :form => { 'field' => 'select', 'options_for_select' => [['On','On'],['Off','Off']] }
  }

attribute 'tlsv1_protocol_enabled',
  :description => 'Enable TLSv1',
  :default => 'true',
  :format => {
    :help => 'If HTTPS is enabled, this determines if the TLSv1 protocol and ciphers are enabled.  Enabling TLSv1 is considered a security vulnarability.  Only TLSv1.1 and above should be used in production. This option is only enabled on CentOS and RHEL versions >= 6.6',
    :category => '3.Security',
    :form => { 'field' => 'checkbox' },
    :order => 5,
  }

attribute 'tlsv11_protocol_enabled',
  :description => 'Enable TLSv1.1',
  :default => 'true',
  :format => {
    :help => 'If HTTPS is enabled, this determines if the TLSv1.1 protocol and ciphers are enabled. This option is only enabled on CentOS and RHEL versions >= 6.6',
    :category => '3.Security',
    :form => { 'field' => 'checkbox' },
    :order => 6,
  }

attribute 'tlsv12_protocol_enabled',
  :description => 'Enable TLSv1.2',
  :default => 'true',
  :format => {
    :help => 'If HTTPS is enabled, this determines if the TLSv1.2 protocol and ciphers are enabled. This option is only enabled on CentOS and RHEL versions >= 6.6',
    :category => '3.Security',
    :form => { 'field' => 'checkbox' },
    :order => 7,
  }

attribute 'php_info',
  :description => 'Enable PHP Info Index',
  :default => 'true',
  :format => {
    :help => 'If an index page is not provided, default behavior is to display an PHP page with information about the server.  Displaying this information is a security vulnarability.  This feature should be disabled in production. ',
    :category => '3.Security',
    :form => { 'field' => 'checkbox' },
    :order => 8,
  }


# modules
attribute 'modules',
  :description => "DSO Modules",
  :data_type => "array",
  :default => '["mod_status","mod_alias","mod_auth_basic","mod_authn_file","mod_authz_default","mod_authz_groupfile","mod_authz_host","mod_authz_user","mod_autoindex","mod_dir","mod_env","mod_mime","mod_negotiation","mod_setenvif","mod_headers"]',
  :format => {
    :help => 'List of modules to be installed and loaded',
    :category => '4.Modules',
    :order => 1
  }

# performance
attribute 'prefork',
  :description => "Prefork Parameters",
  :data_type => "hash",
  :default => '{"startservers":16,"minspareservers":16,"maxspareservers":32,"serverlimit":400,"maxclients":400,"maxrequestsperchild":10000}',
  :format => {
    :help => 'Configure apache MPM prefork directives (see apache website for detailed documentation)',
    :category => '5.Performance',
    :order => 1
  }

attribute 'worker',
  :description => "Worker Parameters",
  :data_type => "hash",
  :default => '{"startservers":4,"maxclients":1024,"minsparethreads":64,"maxsparethreads":192,"maxcthreadsperchild":64,"maxrequestsperchild":0}',
  :format => {
    :help => 'Configure apache MPM worker directives (see apache website for detailed documentation)',
    :category => '5.Performance',
    :order => 1
  }

attribute 'extra',
  :description => "Custom Server Configuration",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter additional apache directives to be included in the server configuration',
    :category => '6.Custom',
    :order => 1
  }

recipe "status", "Apache Status"
recipe "start", "Start Apache"
recipe "stop", "Stop Apache"
recipe "restart", "Restart Apache"
recipe "repair", "Repair Apache"
