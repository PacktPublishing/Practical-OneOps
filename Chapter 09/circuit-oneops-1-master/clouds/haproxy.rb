name "haproxy"
description "haproxy loadbalancer"
auth "haproxy"

service "haproxy",
  :cookbook => 'haproxy',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'lb' }
