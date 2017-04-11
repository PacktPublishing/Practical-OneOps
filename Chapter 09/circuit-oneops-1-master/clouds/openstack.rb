name "openstack"
description "Openstack Cloud"
auth "openstacksecretkey"
is_location "true"

image_map = '{"ubuntu-14.04":"",
              "ubuntu-13.10":"",
              "ubuntu-13.04":"",
              "ubuntu-12.10":"",
              "ubuntu-12.04":"",
              "ubuntu-10.04":"",
              "redhat-7.0":"",
              "redhat-6.5":"",
              "redhat-6.4":"",
              "redhat-6.2":"",
              "redhat-5.9":"",
              "centos-7.0":"",
              "centos-6.5":"",
              "centos-6.4":"",
              "fedora-20":"",
              "fedora-19":""}'

repo_map = '{
      "centos-7.0":"sudo yum -d0 -e0 -y install rsync epel-release",
      "centos-6.5":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-6.4":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-6.2":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
}'


service "designate",
        :description => 'DNS-as-a-Service',
        :cookbook => 'designate',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'dns'},
        :attributes => {
            :endpoint => "http://openstack.example.com/v2.0/tokens",
            :tenant => "",
            :username => "",
            :zone => "example.com",
            :cloud_dns_id => "west1"
        }

service "neutron",
        :description => 'LB-as-a-Service',
        :cookbook => 'neutron',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'lb'},
        :attributes => {
            :endpoint => "http://openstack.example.com/v2.0/tokens",
            :tenant => "",
            :username => ""
        }

service "nova",
        :description => 'Compute-as-a-Service',
        :cookbook => 'openstack',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'compute'},
        :attributes => {
            :endpoint => "http://openstack.example.com/v2.0/tokens",
            :tenant => "",
            :username => "",
            :region => "",
            :subnet => "",
            :imagemap => image_map,
            :repo_map => repo_map
        }

service 'swift',
        :description => 'Swift Storage Service',
        :cookbook => 'swift',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'filestore'},
        :attributes => {
            :endpoint => '',
            :tenant => '',
            :username => '',
            :password => '',
            :regionname => ''
        }
