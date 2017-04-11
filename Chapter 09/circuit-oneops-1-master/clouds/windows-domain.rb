name "windows-domain"
description "Membership in windows domain"
auth ""

service "windows-domain",
  :cookbook => 'windows-domain',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'windows-domain' }
