name "lxd"
description "Lxd"
auth ""
is_location "true"

repo_map = '{
  "centos-7.0":"yum clean all; yum -d0 -e0 -y install sudo rsync yum-utils; yum -d0 -e0 -y install epel-release; yum -y install postfix; systemctl enable postfix; systemctl start postfix",
  "centos-7.2":"yum clean all; yum -d0 -e0 -y install sudo rsync yum-utils; yum -d0 -e0 -y install epel-release; yum -y install postfix; systemctl enable postfix; systemctl start postfix"    
}'

service "lxd",
  :cookbook => 'lxd',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'compute' },
  :attributes => {
    :endpoint => 'http://localhost:8443',
    :repo_map => repo_map
  }
