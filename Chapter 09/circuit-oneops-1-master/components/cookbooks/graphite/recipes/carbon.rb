
relay_destinations = Array.new
node_cores = Array.new
if node["cpu"]["total"] > 9
    (1..9).each do |i|
        relay_destinations.push("127.0.0.1:230#{i}:0#{i}")
        node_cores.push("0#{i}")
    end
    (10..node["cpu"]["total"]).each do |i|
        relay_destinations.push("127.0.0.1:23#{i}:#{i}")
        node_cores.push("#{i}")
    end
else
    (1..node["cpu"]["total"]).each do |i|
        relay_destinations.push("127.0.0.1:230#{i}:0#{i}")
        node_cores.push("0#{i}")
    end
end

# if all VM are named as "compute-x-xxxx", then use all VMs are graphite nodes
# if some VM are named as "console-compute-x-xxxx", then just use "console-compute" VM as graphite nodes. This is for the case when other packs (e.g. Spark) that installed Graphite on "console-compute"

consoleNode = Array.new
hasConsole = false

nodes = node.workorder.payLoad.RequiresComputes
hosts = Array.new
nodes.each do |n|
    if n[:ciName].include? "console"
        consoleNode.push(n)
        hasConsole = true
    end
end

hosts = Array.new
graphiteNode = Array.new

if hasConsole == true
   graphiteNode = consoleNode
else
   graphiteNode = nodes
end


graphiteNode.each do |n|
  hosts.push(n[:ciAttributes][:dns_record])
end

cookbook = node.app_name.downcase
Chef::Log.info("Cookbook is: #{cookbook}")
if cookbook.eql? "graphite"
    graphite_version = node.workorder.rfcCi.ciAttributes.version
else
    graphite_version = node['version']
end

# carbon.conf
template "/opt/graphite/conf/carbon.conf" do
    source "version_#{graphite_version}/carbon-#{graphite_version}.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        :cluster_members => hosts,
        :relay_destinations => relay_destinations,
        :node_cores => node_cores
    )
end

%w{
storage-schemas
storage-aggregation}.each do |item|
    
    override_attribute = "override_" + item
    
    if node.graphite.has_key?("#{override_attribute}") && !node['graphite']['#{item}'].nil?
        file "/opt/graphite/conf/#{item}.conf" do
            content node['graphite']['#{override_attribute}']
        end
    else
        cookbook_file "/opt/graphite/conf/#{item}.conf" do
            source "#{item}.conf.example"
            owner "root"
            group "root"
            mode "0644"
        end
    end
end

# start script
template "/etc/init.d/graphite" do
    source "graphite-scripts.erb"
    owner "root"
    group "root"
    mode "0755"
end

bash "make-graphite-auto-start" do
   user "root"
   code <<-EOF
   chkconfig --add graphite
   (chkconfig graphite on)
   EOF
end

# create
directory "/var/run/carbon" do
    owner "root"
    group "root"
    mode '0755'
    action :create
end

# set up carbonate

# carbonate.conf
template "/opt/graphite/conf/carbonate.conf" do
    source "carbonate.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        :cluster_members => hosts
   )
end

include_recipe "graphite::place_ssh_key"
