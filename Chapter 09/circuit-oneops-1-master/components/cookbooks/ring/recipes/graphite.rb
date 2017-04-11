###DNS RECORD required for fqdn

nodes = node.workorder.payLoad.ManagedVia
dns_record = ""
nodes.each do |n|
  if dns_record == ''
    dns_record = n[:ciAttributes][:dns_record]
  else
    dns_record += ',' + n[:ciAttributes][:dns_record]
  end
end
puts "***RESULT:dns_record=#{dns_record}"
