require 'uri'
require 'openssl'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest-client'
require 'json'
require 'crack'

Chef::Log.info('MADE IT TO PANOS UPDATE RECIPE')

# get the necessary information from the node
service = PanosUtils.get_service_info(node)

addresses = PanosUtils.get_computes(node)
Chef::Log.info("ADDRESSES are: #{addresses}")

tag = PanosUtils.get_tag_name(node)

devicegroups = PanosUtils.get_device_groups(node)

# update the firewall
# could be scaling up/down or replacing a VM (which would be updating an existing address)
panos_firewall 'Update Panos Firewall' do
  url_endpoint service[:url_endpoint]
  username service[:username]
  password service[:password]
  devicegroups devicegroups
  tag tag
  addresses addresses
  action :update
end
