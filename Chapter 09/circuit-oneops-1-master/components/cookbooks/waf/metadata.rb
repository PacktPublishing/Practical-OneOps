name             "Waf"
description      "Web Application Firewall"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :display_name => "Version",
  :description => "Version",
  :type => "string",
  :required => "optional",
  :recipes => [ 'waf::default' ],
  :default => "2.6.3",
  :format => ""

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => '2.6.3',
  :format => {
    :help => 'Version of ModSecurity',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['2.6.3','2.6.3']] }
  }
  
recipe "repair", "Repair Waf"