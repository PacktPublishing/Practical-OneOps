ci = node[:workorder][:ci] || node[:workorder][:rfcCi]

cloud_name = node[:workorder][:cloud][:ciName]
provider = node[:workorder][:services][:compute][cloud_name][:ciClassName]
ip = nil
if provider =~ /openstack/
  ip = ci[:ciAttributes][:private_ip] || ci[:ciAttributes][:public_ip]
else
  ip = ci[:ciAttributes][:public_ip]
end

node.set[:ip] = ip
