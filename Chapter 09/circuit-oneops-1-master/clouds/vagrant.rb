name "vagrant"
description "Vagrant"
auth ""
is_location "true"

repo_map = '{
      "centos-7.0":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/epel-release-6-8.noarch.rpm --replacefiles --replacepkgs",
      "centos-6.5":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --replacefiles --replacepkgs",
      "centos-6.4":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --replacefiles --replacepkgs"
}'

service "vagrant",
  :cookbook => 'vagrant',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'compute' },
  :attributes => {
    :path => '~/Vagrant',
    :repo_map => repo_map,
    :network => 'hostonly'
  }
