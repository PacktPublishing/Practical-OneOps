name             "Infoblox"
description      "DNS Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true


attribute 'host',
  :description => "Host",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Host',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'username',
  :description => "Username",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Username',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Password',
    :category => '1.Authentication',
    :order => 3
  }

attribute 'zone',
  :description => "Zone",
  :default => "",
  :format => {
    :help => 'Specify the zone name where to insert DNS records',
    :category => '2.DNS',
    :order => 1
  }

  attribute 'view_attr',
    :description => "View Attribute",
    :default => "Internal",
    :format => {
      :help => 'specify type of view - internal or default',
      :category => '2.DNS',
      :order => 2
    }

attribute 'cloud_dns_id',
  :description => "Cloud DNS Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Cloud DNS Id - prepended to zone name, but replaced w/ fqdn.global_dns_id for GLB',
    :category => '2.DNS',
    :order => 3
  }
