name             "Designate"
description      "DNS Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
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
  
attribute 'zone',
  :description => "Zone",
  :default => "",
  :format => {
    :help => 'Specify the zone name where to insert DNS records', 
    :category => '2.DNS',
    :order => 1
  }
   
attribute 'cloud_dns_id',
  :description => "Cloud DNS Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Cloud DNS Id - prepended to zone name, but replaced w/ fqdn.global_dns_id for GLB',
    :category => '2.DNS',
    :order => 2
  }

attribute 'domain_owner_email',
  :description => "Domain Owner's email",
  :required => "required",
  :default => "",
  :format => {
    :help => 'any new domains will be created with this users email address',
    :category => '2.DNS',
    :order => 3
  }

attribute 'authoritative_server',
  :description => "authoritative_server",
  :default => "",
  :format => {
    :help => 'Explicit authoritative_server for verification - useful for testing. If not set uses NS records for the zone.',
    :category => '2.DNS',
    :order => 4
  }
      
  