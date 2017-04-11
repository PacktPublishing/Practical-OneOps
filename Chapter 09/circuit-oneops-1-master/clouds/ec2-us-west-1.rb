name "ec2-us-west-1"
description "Amazon Web Services - US West 1 Region (Northern California)"
auth "ec2secretkey"

image_map = '{
      "windows-2008r2":"ami-6cb90605",
      "centos-6.3":"ami-51351b14",
      "centos-6.4":"ami-b9341afc",
      "centos-7.0":"ami-af4333cf",
      "centos-7.2":"ami-af4333cf",
      "ubuntu-14.04":"ami-5f9af43f",
      "ubuntu-13.10":"ami-24a69061",
      "ubuntu-13.04":"ami-40271605",
      "ubuntu-12.10":"ami-daa7919f",
      "ubuntu-12.04":"ami-0ca99f49",
      "ubuntu-10.04":"ami-3aaa9c7f",
      "redhat-6.4":"ami-6283a827",
      "redhat-6.3":"ami-ef99b6aa",
      "redhat-6.2":"ami-4d80af08",
      "redhat-5.9":"ami-859bb4c0",
      "fedora-19":"ami-10cce555",
      "fedora-18":"ami-674f6122"
    }'

repo_map = '{
      "centos-6.3":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-6.4":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "centos-7.2":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'

service "us-west-1",
  :cookbook => 'ec2',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :region => 'us-west-1',
    :availability_zones => "[\"us-west-1a\",\"us-west-1b\"]",
    :imagemap => image_map,
    :repo_map => repo_map
  }
