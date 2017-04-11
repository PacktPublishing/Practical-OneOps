name "azure"
description "Microsoft Azure"
auth "azuresecretkey"

service 'azure-trafficmanager',
        :description => 'GDNS-as-a-Service',
        :cookbook => 'azuretrafficmanager',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'gdns'}

service 'azure-dns',
  :description => 'DNS-as-a-Service',
  :cookbook => 'azuredns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => {:service => 'dns'}

service 'azure-lb',
  :description => 'LB-as-a-Service',
  :cookbook => 'azure_lb',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => {:service => 'lb'}

service 'azure-datadisk',
        :description => 'Storage-as-a-Service',
        :cookbook => 'azuredatadisk',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'storage'}

service 'azure-gateway',
        :description => 'Gateway-as-a-Service',
        :cookbook => 'azuregateway',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'lb'}
