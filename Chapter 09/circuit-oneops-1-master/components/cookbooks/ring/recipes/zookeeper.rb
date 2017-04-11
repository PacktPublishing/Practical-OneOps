###DNS RECORD required for fqdn
nodes = node.workorder.payLoad.ManagedVia

dns_record = ""
nodes.each do |n|
  if dns_record == ''
    dns_record = n[:ciAttributes][:private_ip]
  else
    dns_record += ',' + n[:ciAttributes][:private_ip]
  end
end
puts "***RESULT:dns_record=#{dns_record}"
