name             "Certificate"
description      "Certificate"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]

attribute 'auto_provision',
          :description => 'Auto Generate',
          :default => 'false',
          :format => {
              :help => 'Auto provision the cert using Certificate Service',
              :category => '1.Certificate',
              :form => { 'field' => 'checkbox' },
              :order => 1
          }

attribute 'key',
  :description => "Key",
  :data_type => "text",
  :encrypted => true,
  :default => "",
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:false && pfx_enable:eq:false'}},
    :help => 'Enter the certificate key content (Note: usually this is the content of the *.key file)',
    :tip => 'NOTE:  Certificate auto-provisioning depends on certificate cloud service. If auto-provisioning is ON, the deployment will FAIL for instances in clouds which do not have certificate service configured.',
    :category => '1.Certificate',
    :order => 2
  }

attribute 'cert',
  :description => "Certificate",
  :data_type => "text",
  :default => "",
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:false && pfx_enable:eq:false'}},
    :help => 'Enter the certificate content to be used (Note: usually this is the content of the *.crt file)',
    :category => '1.Certificate',
    :order => 3
  }

attribute 'cacertkey',
  :description => "SSL CA Certificate Key",
  :data_type => "text",
  :default => "",
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:false && pfx_enable:eq:false'}},
    :help => 'Enter the CA certificate keys to be used',
    :category => '1.Certificate',
    :order => 4
  }

attribute 'passphrase',
  :description => "Pass Phrase",
  :encrypted => true,
  :default => "",
  :format => {
    :help => 'Enter the passphrase for the certificate key',
    :category => '1.Certificate',
    :order => 5,
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'pkcs12',
  :description => "Convert to PKCS12",
  :default => 'false',
  :format => {
    :category => '1.Certificate',
    :order => 6,
    :form => { 'field' => 'checkbox' },
    :help => 'Directory path where the certicate files should be saved',
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'expires_in',
  :description => "Time remaining to expiry",
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:false'}},
    :category => '1.Certificate',
    :order => 7,
    :help => 'Expiry time for this certificate. y is for year, m for month, d for day.  Example: 1y, 12m, 365d',
    :pattern => '^[0-9]+(y|m|d)$'
  }

attribute 'expires_on',
  :description => "Expires on absolute date-time",
  :grouping => 'bom',
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:false'}},
    :category => '1.Certificate',
    :order => 8,
    :help => 'Expires on this absolute date-time'
  }

attribute 'common_name',
  :description => "Common Name",
  :default => "",
  :format => {
    :pattern => '^[^.]*$',
    :filter => {'all' => {'visible' => 'auto_provision:eq:true'}},
    :help => 'Enter the common name for the certificate to be provisioned. Do not use dot (.) OneOps will append the domain. Use the field below to add specific SANs',
    :category => '1.Certificate',
    :order => 9 
  }

attribute 'san',
  :description => "Subject Alternative Name",
  :data_type => 'array',
  :default => "",
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:true'}},
    :help => 'Enter the SANs (Subject Alternative Names) for the certificate to be provisioned',
    :category => '1.Certificate',
    :order => 10
  }

attribute 'external',
  :description => "External (Internet Facing)",
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:true'}},
    :category => '1.Certificate',
    :order => 11,
    :form => { 'field' => 'checkbox' },
    :help => 'Is Internet facing certificate'
  }

attribute 'domain',
  :description => "Domain Name",
  :default => "", 
  :format => {
    :filter => {'all' => {'visible' => 'auto_provision:eq:true'}},
    :help => 'Required for internet facing cert. Optional field if requesting internal certificate',
    :category => '1.Certificate',
    :order => 12
  }

attribute 'path',
  :description => "Directory Path",
  :default => "/var/lib/certs",
  :format => {
    :category => '2.Destination',
    :order => 1,
    :help => 'Directory path where the certicate files should be saved',
    :filter => {'all' => {'visible' => 'pfx_enable:eq:false'}}
  }

attribute 'pfx_enable',
          :description => 'SSL Certificate (PFX)',
          :default => "false",
          :format => {
              :help => 'Enable it to upload .pfx file data for Application Gateway/Certificate store.',
              :category => '3.PFX format',
              :order => 1,
              :form => {'field' => 'checkbox'}
          }

attribute 'ssl_data',
          :description => "Data",
          :data_type => "text",
          :default => "",
          :format => {
              :help => 'Enter the base-64 encoded form of the .pfx file.',
              :category => '3.PFX format',
              :order => 2,
              :filter => {'all' => {'visible' => 'pfx_enable:eq:true'}}
          }

attribute 'ssl_password',
          :description => "Password",
          :encrypted => true,
          :default => "",
          :format => {
              :help => 'Enter password for a .pfx certificate.',
              :category => '3.PFX format',
              :order => 3,
              :filter => {'all' => {'visible' => 'pfx_enable:eq:true'}}
          }
recipe "repair", "Repair"

