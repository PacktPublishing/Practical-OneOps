name "digitalocean"
description "Digitial Ocean"
auth "dosecretkey"

image_map = '{
	"centos-7.2":"centos-7-2-x64",
	"centos-7.0":"centos-7-0-x64"
}'

repo_map = '{
	"centos-7.2":"sudo yum clean all;sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
	"centos-7.0":"sudo yum clean all;sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'

service "digitalocean-droplet",
   :description => 'Digital Ocean Droplet',
   :cookbook => 'digitalocean',
   :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
   :provides => { :service => 'compute' },
   :attributes => {
	:region => "",
	:api_key => "",
	:subnet => "",
	:imagemap => image_map,
	:repo_map => repo_map
}
