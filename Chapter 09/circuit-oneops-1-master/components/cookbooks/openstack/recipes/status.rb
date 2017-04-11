#
# openstack::status - gets quota info
#

require 'fog'
require 'json'

token = node[:workorder][:ci][:ciAttributes]
size_map = JSON.parse(token[:sizemap])

conn = Fog::Compute.new({
                            :provider => 'OpenStack',
                            :openstack_api_key => token[:password],
                            :openstack_username => token[:username],
                            :openstack_tenant => token[:tenant],
                            :openstack_auth_url => token[:endpoint]
                        })

limits_all = conn.get_limits.body["limits"]

limits = limits_all["absolute"]
Chef::Log.info("limits: "+limits.inspect)

puts "***RESULT:max_instances=#{limits['maxTotalInstances']}"
puts "***RESULT:max_cores=#{limits['maxTotalCores']}"
puts "***RESULT:max_ram=#{limits['maxTotalRAMSize']}"
puts "***RESULT:max_keypairs=#{limits['maxTotalKeypairs']}"
puts "***RESULT:max_secgroups=#{limits['maxSecurityGroups']}"

flavors = conn.list_flavors_detail.body["flavors"]
Chef::Log.info("flavors: "+flavors.inspect)
flavor_vcpu_map = {}
flavors.each do |f|
  if !size_map.key(f["id"]).nil?
    flavor_vcpu_map[size_map.key(f["id"])] = f["vcpus"].to_s+" cores / "+f["ram"].to_s+" MB /" + f["OS-FLV-EXT-DATA:ephemeral"].to_s+" GB"
  end
end

puts "***RESULT:flavormap="+JSON.dump(flavor_vcpu_map)