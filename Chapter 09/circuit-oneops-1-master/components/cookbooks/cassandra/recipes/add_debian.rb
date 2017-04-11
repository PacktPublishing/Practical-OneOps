#
# Author:: Benjamin Black (<b@b3k.us>)

package "libjna-java"

dist = node.workorder.rfcCi.ciAttributes.version
availability_mode = node.workorder.box.ciAttributes.availability

nodes = node.workorder.payLoad.RequiresComputes 

filtered_nodes = []
nodes.each do |n|
  next if n[:ciAttributes][:private_ip].nil? || n[:ciAttributes][:private_ip].empty?
  filtered_nodes.push n
end
node.default[:initial_seeds] = filtered_nodes.collect { |n| n[:ciAttributes][:private_ip] }

version_parts = dist.split(".")
if version_parts.size > 2
  version_parts.pop
end
# to share config templates by minor version
dist = version_parts.join(".")  
v = version_parts.join("") + "x"
  

include_recipe "cassandra::add_user_dirs"
directory "/etc/cassandra" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  not_if "test -d /etc/cassandra"
end

execute "ln -sf /etc/cassandra /opt/cassandra/conf"

private_ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]

file "/etc/default/cassandra" do
  owner "root"
  group "root"
  mode "0644"
  content "JVM_OPTS=\"-Dcassandra.join_ring=false -Djava.rmi.server.hostname=#{private_ip}\""
  action :create
  not_if { availability_mode == "single" }
end

template "/etc/cassandra/cassandra.yaml" do
  source "cassandra-#{dist}.yaml.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/cassandra/cassandra-env.sh" do
  source "cassandra-env.sh.erb"
  owner "root"
  group "root"
  mode 0644
end


cassandra_repository "cassandra" do
  uri "http://www.apache.org/dist/cassandra/debian"
  distribution v
  components ["main"]
  # key "F758CE318D77295D"
  # keyserver "wwwkeys.eu.pgp.net"
  action :add
end

include_recipe "cassandra::apt"

ruby_block 'Check for dpkg lock' do
  block do   
    sleep rand(10)
    retry_count = 0
    while system('lsof /var/lib/dpkg/lock') && retry_count < 20
      Chef::Log.warn("Found lock. Will retry package #{name} in #{node.workorder.rfcCi.ciName}")
      sleep rand(5)+10
      retry_count += 1
    end
  end
end
    
package "cassandra" do
  options '--force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'
  action :install
end

