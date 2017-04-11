#
# Cookbook Name:: queue
# Recipe:: delete
#
require 'json'

require 'json'

payload = node.workorder.payLoad
depends_on = Array.new

if payload.has_key?('DependsOn')
  depends_on = payload.DependsOn.select { |broker|
    broker['ciClassName'].split('.').last == "activemq"
  }
end

broker_type = ""
case
when depends_on.size == 0
  pack_name = node.workorder.box.ciAttributes["pack"]
  if pack_name =~ /activemq/
    broker_type = pack_name
    Chef::Log.info("Using broker_type: "+broker_type+ " via box")
  else
    raise "Unable to find a broker information in the request. Exiting."
  end

when depends_on.size == 1
  broker = depends_on.first
  Chef::Log.info("Using broker #{broker['ciName']}")
    broker_type = "#{broker['ciName']}"
end

include_recipe "queue::#{broker_type}_delete"
