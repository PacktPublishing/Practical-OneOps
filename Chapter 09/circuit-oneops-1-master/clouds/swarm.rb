name "swarm"
description "Docker Swarm"

service "swarm",
  :cookbook => 'swarm',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'container' }
