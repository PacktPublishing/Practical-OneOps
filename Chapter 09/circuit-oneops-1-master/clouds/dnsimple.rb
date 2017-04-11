name "dnsimple"
description "DNSimple"
auth "dnsimplesecretkey"
  
service "dnsimple",
  :cookbook => 'dnsimple',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'dns' }