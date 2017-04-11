name "azure-southindia"
description "Microsoft Azure"
auth "5D5F7299-F921-4240-B4C8-C5B6433F256C"

image_map = '{
      "centos-7.0":"OpenLogic:CentOS:7.0:latest",
      "ubuntu-14.04":"canonical:ubuntuserver:14.04.3-LTS:14.04.201508050",
      "windows_2012_r2":"Microsoftwindowsserver:windowsserver:2012-R2-Datacenter:4.0.20161109"
    }'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "windows_2012_r2":""
}'

env_vars = '{ "rubygems":"https://rubygems.org/"}'

service "azure-southindia",
  :cookbook => 'azure',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :location => 'southindia',
    :ostype => '["CentOS-7","Windows"]',
    :imagemap => image_map,
    :repo_map => repo_map,
    :env_vars => env_vars
  }
