nodes = node.workorder.payLoad.ManagedVia
depends_on=node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /ElasticSearch/ }

service "elasticsearch" do
  action :stop
end

numMasterNodes = (nodes.length / 2).floor + 1
unicastNodes = ''
# build a list of nodes in the cluster
nodes.each do |n|
  if unicastNodes == ''
    unicastNodes = n[:ciAttributes][:private_ip]
  else
    unicastNodes += ',' + n[:ciAttributes][:private_ip]
  end
end

puts "ElasticSearch:unicastNodes=#{unicastNodes}"
puts "ElasticSearch:nodes=#{nodes.length}"
puts "ElasticSearch:master-nodes=#{numMasterNodes}"

# update the configuration with the list of master nodes
ruby_block "allow ES node to join the cluster" do
  block do
    # TODO: how to get this value dynamically?
    esconfig = Chef::Util::FileEdit.new("/usr/local/etc/elasticsearch/elasticsearch.yml")
    esconfig.search_file_replace_line("^discovery.zen.ping.unicast.hosts.*", "discovery.zen.ping.unicast.hosts: [#{unicastNodes}]")
    esconfig.search_file_replace_line("^discovery.zen.minimum_master_nodes.*", "discovery.zen.minimum_master_nodes: #{numMasterNodes}")
    esconfig.write_file
  end
end

# the node has to be restarted so that our configuration changes will be used
service "elasticsearch" do
  action :start
end

