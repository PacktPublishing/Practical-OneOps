#
# Cookbook Name:: Sensuclient
# Recipe:: delete
#
# Copyright 2016, kaushiksriram100@gmail.com
#
# Apache 2.0
#
include_recipe "sensuclient::stop"

	installed_version=`rpm -qa|grep -i sensu|tr --delete '\n'`

                rpm_package "#{installed_version}" do
                        action :remove
                end
                
`rm -rf /var/log/sensu`
`rm -rf /etc/sensu`
`rm -rf /var/run/sensu`
`rm -rf /usr/lib/sensu-community`
