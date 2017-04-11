require 'fog'

Chef::Log.info("cibadmin -E --force && crm configure erase")
Chef::Log.info(`cibadmin -E --force 2>&1`)
Chef::Log.info(`crm configure erase 2>&1`)

avail_zone = node.workorder.zone.ciName.split(".")[1]
r =  /(.*\d)[a-z]$/
m = r.match avail_zone
region = ''
if m != nil
  region = m[1]
end

if node.workorder.zone.ciAttributes.has_key?("region")
  region = node.workorder.zone.ciAttributes.region
end

is_ip_based = true
if node.workorder.rfcCi.ciAttributes.shared_type == 'dns'
  is_ip_based = false
end

if is_ip_based
  conn = Fog::Compute.new(:provider => 'AWS', :region => region,
    :aws_access_key_id => node.workorder.token.ciAttributes.key,
    :aws_secret_access_key => node.workorder.token.ciAttributes.secret )

  address = conn.addresses.get(node.workorder.rfcCi.ciAttributes.shared_ip)
  address.destroy
end