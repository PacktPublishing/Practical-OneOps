# gmond - Install the Ganglia monitoring daemon
#
# This recipe installs all of the components that are required for
# Ganglia's monitoring daemon (gmond).

Chef::Log.info("Running #{node['app_name']}::gmond")

require 'json'

require File.expand_path("../spark_helper.rb", __FILE__)

sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]

spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

# install gmond
package 'ganglia-gmond'

# default config for ganglia gmond
cookbook_file "/etc/ganglia/gmond.conf" do
    source "gmond.conf"
    owner "root"
    group "root"
    mode "0644"
end

# define ganglia_servers here:
if (configNode['ganglia_servers'].nil? || configNode['ganglia_servers'].empty?)
  Chef::Log.debug("NO Ganglia server specified")
  ganglia_servers = nil
else
  ganglia_servers = configNode['ganglia_servers'].split(',')
  Chef::Log.debug("Ganglia servers: #{ganglia_servers}")
end

upstream_servers = ganglia_servers

# ganglia config for yarn
template "/etc/ganglia/conf.d/delivered-gmond.conf" do
    source "delivered-gmond.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables ({
      :ganglia_servers => upstream_servers,
      :cluster_name => "#{node.workorder.payLoad.Assembly[0].ciName}_#{node.workorder.payLoad.Environment[0].ciName}",
      :owner_name => node.workorder.payLoad.Assembly[0].ciAttributes.owner,
      :hostname => node.workorder.payLoad.ManagedVia[0].ciName
    })
    notifies :restart, "service[gmond]"
end

# define service
service "gmond" do
    action [:start, :enable]
    supports :restart => true, :reload => true
end

metrics_port = "8080"
metrics_path = "master/json/"

if !is_spark_master && !is_client_only
  # Change the port and path to the worker settings if this is a worker
  metrics_port = "8081"
  metrics_path = "json/"
end

sparkGmetric = "#{spark_dir}/spark_gmetric.sh"

# Create a template for the Spark metrics script
template sparkGmetric do
    source "spark-gmetric.sh.erb"
    owner "spark"
    group "spark"
    mode "0755"
    variables ({
      :metrics_port => metrics_port,
      :metrics_path => metrics_path,
      :is_spark_master => is_spark_master
    })
  not_if { is_client_only }
end

sparkMetricCronD = "/etc/cron.d/spark_metrics"

# Schedule the Spark metrics script to run every minute if Ganglia is enabled
file sparkMetricCronD do
  content <<-EOF#!/bin/bash

SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin

* * * * * root #{spark_dir}/spark_gmetric.sh
EOF
  mode    '0644'
  owner   'root'
  group   'root'
  not_if { is_client_only || ganglia_servers.nil? }
end

# Delete the Spark metrics script entry if Ganglia is not enabled
file sparkMetricCronD do
  action :delete
  only_if { !is_client_only && ganglia_servers.nil? }
end