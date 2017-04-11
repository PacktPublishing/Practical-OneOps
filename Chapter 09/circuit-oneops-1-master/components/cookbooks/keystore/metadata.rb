name             "Keystore"
description      "Keystore"
maintainer       "OneOps"
version          "0.1"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'keystore_filename',
  :description => "Keystore Filename",
  :default => "",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Enter the certificate Keystore Filename',
    :category => '1.Location',
    :order => 1
  }

attribute 'keystore_password',
  :description => "Keystore Password",
  :default => "",
  :encrypted => true,
  :required => "required",
  :format => {
    :help => 'Enter the Keystore Password',
    :category => '1.Location',
    :order => 2
  }

recipe "repair", "Repair"
