name "aliyun-cn-beijing"
description "Alibaba Cloud"
auth "alisecretkey"

image_map = '{
  "centos-7.0":"centos7u0_64_40G_aliaegis_20160120.vhd"
}'

repo_map = '{
  "centos-7.0":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/epel-release-6-8.noarch.rpm"
}'

service "aliyun-ecs-cn-beijing",
  :cookbook => 'aliyun',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'compute' },
  :attributes => {
    :url => 'https://ecs.aliyuncs.com',
    :region => 'cn-beijing',
    :availability_zones => "[\"cn-beijing-a\",\"cn-beijing-b\",\"cn-beijing-c\"]",
    :imagemap => image_map,
    :repo_map => repo_map
}