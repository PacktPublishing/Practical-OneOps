name "ec2-us-east-2"
description "Amazon Web Services - US East 2 Region (Ohio)"
auth "ec2secretkey"

image_map = '{
      "centos-7.0":"ami-6a2d760f"
    }'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'
  
service "us-east-2",
  :cookbook => 'ec2',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :region => 'us-east-2',
    :availability_zones => "[\"us-east-2a\",\"us-east-2b\",\"us-east-2c\"]",
    :imagemap => image_map,
    :repo_map => repo_map
  }
