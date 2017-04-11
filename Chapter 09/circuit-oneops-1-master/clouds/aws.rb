name "aws"
description "Amazon Web Services"
auth "awssecretkey"

service "ebs",
  :cookbook => 'ebs',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'storage' }

service "elb",
  :cookbook => 'elb',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'lb' }

service "s3",
  :cookbook => 's3',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'filestore' }
   
service "route53",
  :cookbook => 'route53',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'dns' }

service "route53-gdns",
  :cookbook => 'route53',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'gdns' }
