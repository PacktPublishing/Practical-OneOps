name "vsphere"
description "VMware vSphere"
auth "vspherepublickey"

service "vsphere",
  :cookbook => 'vsphere',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'compute' }
