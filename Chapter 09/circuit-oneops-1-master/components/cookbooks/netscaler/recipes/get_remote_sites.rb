remote_sites = Array.new

cloud_name = node.workorder.cloud.ciName
cloud_service = node[:workorder][:services][:gdns][cloud_name]

node.workorder.payLoad.remotegdns.each do |service|
  if service[:ciAttributes].has_key?("gslb_site") && 
     service[:ciAttributes][:gslb_site] != cloud_service[:ciAttributes][:gslb_site]

    remote_sites.push service
  end
end
node.set["remote_sites"] = remote_sites
