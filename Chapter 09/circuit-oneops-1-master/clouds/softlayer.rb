name "softlayer"
description "SoftLayer"
auth "softlayersecretkey"
is_location "true"

size_map = '{
    "XS":"m1.tiny",
    "S":"m1.small",
    "M":"m1.medium",
    "L":"m1.large",
    "XL":"m1.xlarge"
}'

image_map = '{
    "ubuntu-16.04":"d4bd5bfb-4b7c-4fb0-b742-ed548d8bd1e7",
    "ubuntu-14.04":"ad42bfe1-7c8d-4784-8559-4ff9d2648cdb",
    "ubuntu-12.04":"f5b8a615-84ea-4527-96fa-be07b453c591",
    "redhat-6":"cc30a0a6-b0f1-4db1-82d4-215977aba61d",
    "redhat-5":"185aabae-0dca-477e-8f74-1a649bda45fa",
    "centos-7":"ebf2c369-19e4-4f90-b43d-2be32ae4e4b9",
    "centos-6":"54f4ed9f-f7e6-4fe6-8b54-3a7faacd82b3",
    "centos-5":"29073a7a-2fac-405c-b59f-4de8ad6e4945",
    "fedora-15":"53bd113b-29ab-4f4b-83a2-514d56174dfe"
}'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "ubuntu-14.04":""
}'

service "softlayer",
  :description => 'Softlayer VSI',
  :cookbook => 'softlayer',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'compute' },
  :attributes => {
    :username => "",
    :apikey => "",
    :datacenter => "dal10",
    :sizemap => size_map,
    :imagemap => image_map,
    :repo_map => repo_map
  }
