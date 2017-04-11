nodes = node.workorder.payLoad.ManagedVia
depends_on = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Mongodb/ }

chosen     = depends_on.first
user       = chosen[:ciAttributes][:mongodbuser]
group      = chosen[:ciAttributes][:mongodbgroup]
apath      = chosen[:ciAttributes][:apppath]
replport   = chosen[:ciAttributes][:port]

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

node.default[:members] = nodes.collect { |n| { '_id' => n[:ciName].split('-').last.to_i - 1, 'host' => "#{n[:ciAttributes][:private_ip]}:#{replport}" } }

#Create the mongodb.conf start config file
template "/tmp/setup_replset.js" do
  source "mongodb_setup_replset.js.erb"
  owner "root"
  group "root"
  mode 0644
end

#Initiate the replication set
execute "Setup Mongodb replication set" do
  command "mongo local /tmp/setup_replset.js"
  only_if "echo 'rs.status()' | mongo local --quiet | grep -q 'run rs.initiate'"
end