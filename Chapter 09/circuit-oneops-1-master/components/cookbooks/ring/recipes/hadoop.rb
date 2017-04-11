nodes = node.workorder.payLoad.RequiresComputes
depends_on = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Hadoop/ }

chosen     = depends_on.first
user       = chosen[:ciAttributes][:hadoopuser]
group      = chosen[:ciAttributes][:haddopgroup]
dpath      = chosen[:ciAttributes][:datapath]

# dns_record used for fqdn
dns_record = ""
nodes.each do |n|
  if dns_record == ""
    dns_record = n[:ciAttributes][:dns_record]
  else
    dns_record += ","+n[:ciAttributes][:dns_record]
  end
end
puts "***RESULT:dns_record=#{dns_record}"

#Hadoop ring deployment
#node.default[:members] = nodes.collect { |n| { '_id' => n[:ciName].split('-').last.to_i - 1, 'host' => "#{n[:ciAttributes][:private_ip]} } }

