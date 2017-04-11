name "mirror"
description "Public Software Mirrors"
auth "mirrorsecretkey"
  
service "mirrors-public",
  :cookbook => 'mirror',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'mirror' },
  :attributes => {
    :mirrors => '{
      "apache":"http://archive.apache.org/dist"
    }'
  }
