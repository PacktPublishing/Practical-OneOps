# get authoratative NS's and find one we can connect to
cloud_name = node[:workorder][:cloud][:ciName]
service_attrs = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
ns_list = `dig +short NS #{service_attrs[:zone]}`.split("\n")
ns = nil
ns_list.each do |n|
  `nc -w 2 #{n} 53 </dev/null`
  if $?.to_i == 0
    ns = n
    break
  else
    Chef::Log.info("cannot connect to ns: #{n} ...trying another")
  end
end

if service_attrs.has_key?("authoritative_server") && !service_attrs[:authoritative_server].empty?
  ns = service_attrs[:authoritative_server]
end

Chef::Log.info("authoritative_dns_server: "+ns.inspect)
node.set["ns"] = ns
node.set["ns_list"] = ns_list