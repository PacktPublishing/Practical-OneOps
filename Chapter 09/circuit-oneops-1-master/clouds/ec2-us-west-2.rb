name "ec2-us-west-2"
description "Amazon Web Services - US West 2 Region (Oregon)"
auth "ec2secretkey"

image_map = '{
      "windows-2008r2":"ami-6cb90605",
      "centos-6.3":"ami-bd58c98d",
      "centos-6.4":"ami-b158c981",
      "centos-7.0":"ami-d2c924b2",
      "centos-7.2":"ami-d2c924b2",
      "ubuntu-14.04":"ami-e54f5f84",
      "ubuntu-13.10":"ami-ee940fde",
      "ubuntu-13.04":"ami-c6e973f6",
      "ubuntu-12.10":"ami-10891220",
      "ubuntu-12.04":"ami-50b22960",
      "ubuntu-10.04":"ami-02bd2632",
      "redhat-6.4":"ami-b8a63b88",
      "redhat-6.3":"ami-55df4e65",
      "redhat-6.2":"ami-2fd5441f",
      "redhat-5.9":"ami-87d948b7",
      "fedora-19":"ami-9727b7a7",
      "fedora-18":"ami-fd9302cd"
    }'

repo_map = '{
      "centos-6.3":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-6.4":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "centos-7.2":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'

service "us-west-2",
  :cookbook => 'ec2',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :region => 'us-west-2',
    :availability_zones => "[\"us-west-2a\",\"us-west-2b\",\"us-west-2c\"]",
    :imagemap => image_map,
    :repo_map => repo_map
  }
