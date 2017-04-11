#
# openstack::status - gets quota info
# 

require 'fog'

token = node[:workorder][:ci][:ciAttributes]

begin
conn = Fog::Volume.new({
  :provider => 'OpenStack',
  :openstack_api_key => token[:password],
  :openstack_username => token[:username],
  :openstack_tenant => token[:tenant],
  :openstack_auth_url => token[:endpoint]
})
Chef::Log.info("credentials ok")

rescue Exception => e
  Chef::Log.error("credentials bad: #{e.inspect}")
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
