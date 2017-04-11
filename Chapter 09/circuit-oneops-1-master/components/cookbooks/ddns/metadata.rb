name             "Ddns"
description      "DDNS Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'keyname',
  :description => "Key Name",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Key Name',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'secret',
  :description => "Secret",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Secret',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'algorithm',
  :description => "Algorithm",
  :required => "required",
  :default => "HMAC-MD5",
  :format => {
    :help => 'Algorithm',
    :category => '1.Authentication',
    :order => 3
  }
  
attribute 'zone',
  :description => "Zone",
  :required => "required",
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


attribute 'authoritative_server',
  :description => "authoritative_server",
  :default => "",
  :format => {
    :help => 'Explicit authoritative_server for verification - useful for testing. If not set uses NS records for the zone.',
    :category => '2.DNS',
    :order => 3
  }

