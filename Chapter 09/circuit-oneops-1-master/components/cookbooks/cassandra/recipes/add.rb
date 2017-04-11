#
# cassandra::add
#

include_recipe "cassandra::validate_config"

case node.platform
  when "ubuntu"
    include_recipe "cassandra::add_debian"
  when "redhat"
    include_recipe "cassandra::add_redhat"
  when "centos"
    include_recipe "cassandra::add_redhat"
  when "fedora"
    include_recipe "cassandra::add_redhat"
  else
    Chef::Log.error("platform not supported yet")
end

seeds = []
if node.workorder.rfcCi.ciAttributes.has_key?("seeds") &&
   !node.workorder.rfcCi.ciAttributes.seeds.empty?

   tmp_seeds = JSON.parse(node.workorder.rfcCi.ciAttributes.seeds)
   if tmp_seeds.size > 0
     seeds = tmp_seeds
   end
end

#Discover seeds if not provided
if seeds.empty?
  ipaddress = node[:ipaddress]
  action = node.workorder.has_key?("rfcCi") ? node.workorder.rfcCi.rfcAction : node.workorder.actionName
  seed_count = node.workorder.rfcCi.ciAttributes.seed_count
  if !node.workorder.rfcCi.ciBaseAttributes.has_key?("seed_count") || seed_count != node.workorder.rfcCi.ciBaseAttributes.seed_count
    seeds = 'replace'.eql?(action) ? Cassandra::Util.discover_seed_nodes(node,seed_count.to_i,ipaddress) : Cassandra::Util.discover_seed_nodes(node,seed_count.to_i)
  end
end
Chef::Log.info("seeds : #{seeds.join(',')}")

node.default[:initial_seeds] = seeds
node.default[:auth_enabled] = node.workorder.rfcCi.ciAttributes.has_key?("auth_enabled") ? node.workorder.rfcCi.ciAttributes.auth_enabled : 'false'

if node.workorder.rfcCi.ciAttributes.version.to_f > 2.0
   execute "ln -sf /var/lib/cassandra /opt/cassandra/data"
   execute "ln -sf /var/log/cassandra /opt/cassandra/logs"
end

# Update config directives after the add logic
include_recipe "cassandra::config_directives"

include_recipe "cassandra::limits"

include_recipe "cassandra::topology"

`echo "export PATH=$PATH:/opt/cassandra/bin" > /etc/profile.d/oneops_cassandra.sh`

include_recipe "cassandra::initial_startup"

execute "chmod a+rx /etc/init.d/cassandra"
