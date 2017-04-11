name             "Swarm"
description      "Docker Swarm"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'service.compute', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'endpoint',
  :description => "API Endpoint Host",
  :default => "",
  :format => {
    :help => 'API Endpoint Host',
    :important => true,
    :category => '1.Authentication',
    :order => 1
  }

attribute 'env_vars',
  :description => "Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Set docker environment variables when running docker client (example: DOCKER_HOST, DOCKER_MACHINE_NAME, DOCKER_CERT_PATH, DOCKER_TLS_VERIFY)',
    :category => '1.Authentication',
    :order => 2
  }
