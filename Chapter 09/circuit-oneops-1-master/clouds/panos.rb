name "panos"
description "Palo Alto Firewall"
auth "panossecretkey"

service 'panos',
  :description => 'FW-as-a-Service',
  :cookbook => 'panos',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => {:service => 'firewall'},
  :attributes => {
    :endpoint => 'URL to firewall or panorama device',
    :username => 'changeme',
    :password => 'changeme'
  }
