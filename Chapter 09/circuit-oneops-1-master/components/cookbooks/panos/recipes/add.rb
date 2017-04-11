require 'uri'
require 'openssl'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest-client'
require 'json'
require 'crack'

Chef::Log.info('MADE IT TO PANOS ADD RECIPE')

# get the necessary information from the node
service = PanosUtils.get_service_info(node)

addresses = PanosUtils.get_computes(node)
Chef::Log.info("ADDRESSES are: #{addresses}")

address_group_name = PanosUtils.get_address_group_name(node)
tag = PanosUtils.get_tag_name(node)

devicegroups = PanosUtils.get_device_groups(node)

# create the dynamic address group and addresses for all the computes
panos_firewall 'Add Panos Firewall' do
  url_endpoint service[:url_endpoint]
  username service[:username]
  password service[:password]
  devicegroups devicegroups
  address_group_name address_group_name
  addresses addresses
  tag tag
  action :add
end
