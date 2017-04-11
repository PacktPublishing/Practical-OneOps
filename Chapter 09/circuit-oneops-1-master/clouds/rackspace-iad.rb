name "rackspace-iad"
description "Rackspace IAD (Northern Virginia)"
auth "rackspacesecretkey"
is_location "true"

image_map = '{
      "centos-7.2":"409c8b56-ca41-4211-a305-3beb70a70f21"
}'

repo_map = '{
      "centos-7.2":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'

service "rackspace-iad",
  :description => 'Compute-as-a-Service Rackspace IAD',
  :cookbook => 'rackspace',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'compute' },
  :attributes => {
    :tenant => "",
    :username => "",
    :region => "IAD",
    :subnet => "",
    :imagemap => image_map,
    :repo_map => repo_map
  }

service "rackspace-iad-lb",
  :description => 'Lb-as-a-Service Rackspace IAD',
  :cookbook => 'rackspace',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'lb' },
  :attributes => {
    :tenant => "",
    :username => "",
    :api_key => "",
    :region => "IAD"
  }

service "rackspace-gdns",
  :description => 'GDNS-as-a-Service Rackspace',
  :cookbook => 'rackspacedns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'gdns' },
  :attributes => {
    :username => "",
    :api_key => ""
  }

