name "ddns"
description "DynamicDNS / nsupdate"
auth "ddnskey"

service "ddns",
  :cookbook => 'ddns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'dns' }
