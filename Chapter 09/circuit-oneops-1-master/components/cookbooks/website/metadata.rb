name             "Website"
description      "Website"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'server_name',
  :description => "Server Name",
  :default => "",
  :format => {
    :important => true,
    :help => 'Hostname and port that the server uses to identify itself',
    :category => '1.Global',
    :order => 1
  }

attribute 'port',
  :description => "Listen Port",
  :required => "required",
  :default => "80",
  :format => {
    :important => true,
    :help => 'Website port where the server will listen for incoming requests',
    :category => '1.Global',
    :order => 2
  }

attribute 'root',
  :description => "Document Root",
  :default => "",
  :format => {
    :important => true,
    :help => 'Directory that forms the main document tree visible from the web',
    :category => '1.Global',
    :order => 3
  }

attribute 'directives',
  :description => "Document Root Options",
  :data_type => "text",
  :default => "Options Indexes FollowSymLinks MultiViews
        AllowOverride None
        Order allow,deny
        allow from all",
  :format => {
    :help => 'Optional directives to be applied to the document root',
    :category => '1.Global',
    :order => 4
  }

attribute 'ssl',
  :description => "SSL",
  :default => "off",
  :format => {
    :important => true,
    :help => 'Enable SSL for incoming requests (Note: make sure you have the port set to 443 if you want to use the standard SSL port)',
    :category => '2.SSL',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['On','on'],['Off','off']] }
  }


attribute 'sslcert',
  :description => "SSL Certificate",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter the SSL certificate content to be used for this website (Note: usually this is the content of the *.crt file)',
    :category => '2.SSL',
    :order => 2
  }

attribute 'sslcertkey',
  :description => "SSL Certificate Key",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter the SSL certificate key content to be used for this website (Note: usually this is the content of the *.key file)',
    :category => '2.SSL',
    :order => 3
  }

attribute 'sslcacertkey',
  :description => "SSL CA Certificate Key",
  :data_type => "text",
  :default => "",
  :format => {
    :help => 'Enter the SSL CA certificate keys to be used for this website',
    :category => '2.SSL',
    :order => 4
  }

attribute 'upstream',
  :description => "Upstream Proxies",
  :data_type => "hash",
  :default => "{}",
  :format => {
    :category => '3.Upstream',
    :order => 1,
    :help => 'Used in apache virtual host configuration'
  }

attribute 'location',
  :description => "Location Definitions",
  :data_type => "text",
  :default => "",
  :format => {
    :category => '3.Upstream',
    :order => 2,
    :help => 'Used for configuring nginx servers'
  }


attribute 'extra',
  :description => "Additional Configuration Directives",
  :data_type => "text",
  :default => "",
  :format => {
    :category => '4.Custom',
    :order => 1,
    :help => 'Enter any configuration directives that work within virtual host context'
  }

recipe "repair", "Repair Website"
