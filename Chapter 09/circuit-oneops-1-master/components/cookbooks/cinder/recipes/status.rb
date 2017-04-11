#
# openstack::status - gets quota info
# 

require 'fog'

token = node[:workorder][:ci][:ciAttributes]

conn = Fog::Volume.new({
  :provider => 'OpenStack',
  :openstack_api_key => token[:password],
  :openstack_username => token[:username],
  :openstack_tenant => token[:tenant],
  :openstack_auth_url => token[:endpoint]
})

limits = conn.get_quota(conn.current_tenant["id"]).body["quota_set"]

Chef::Log.info("limits: "+limits.inspect)

puts "***RESULT:max_total_volume_gigabytes=#{limits['gigabytes']}"
puts "***RESULT:max_total_snapshots=#{limits['snapshots']}"
puts "***RESULT:max_total_volumes=#{limits['volumes']}"
puts "***RESULT:max_total_backups=#{limits['backups']}"
puts "***RESULT:max_total_backup_gigabytes=#{limits['backup_gigabytes']}"

total_volumes = 0
total_gigabytes = 0
conn.volumes.each do |vol|
  total_volumes += 1
  total_gigabytes += vol.size
end

puts "***RESULT:total_gigabytes_used=#{total_gigabytes}"
puts "***RESULT:total_volumes_used=#{total_volumes}"

snapshots = conn.list_snapshots.body["snapshots"]
puts "***RESULT:total_snapshots_used=#{snapshots.size}"

# backup api not implemented in fog as of 1.31
# TODO: add total_backups_used, total_backup_gigabytes when fog has it
