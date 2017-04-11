name             'Neutron'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures neutron'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'endpoint',
  :description => "API Endpoint",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Endpoint URL',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'tenant',
  :description => "Tenant",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Tenant Name',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Username',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Password',
    :category => '1.Authentication',
    :order => 4
  }

attribute 'subnet_name',
  :description => "Subnet Name",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Subnet Name',
    :category => '2.Configuration',
    :order => 1
  }

attribute 'provider',
  :description => "Provider",
  :required => "required",
  :default => "Octavia",
  :format => {
    :help => '',
    :category => '2.Configuration',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Octavia','Octavia']]
  }
}

attribute 'gslb_site_dns_id',
  :description => "GSLB Site DNS id",
  :default => '',
  :format => {
      :category => '2.Configuration',
      :order => 3,
      :help => 'GSLB Site DNS id'
  }

recipe "status", "Neutron Status"
