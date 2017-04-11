name "kubernetes"
description "Kubernetes"

service "kubernetes",
  :cookbook => 'kubernetes',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'container' }
