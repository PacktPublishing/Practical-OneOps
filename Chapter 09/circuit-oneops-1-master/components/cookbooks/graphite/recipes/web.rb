
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

remote_ip = Array.new
graphiteNode = Array.new

# if all VM are named as "compute-x-xxxx", then use all VMs are graphite nodes
# if some VM are named as "console-compute-x-xxxx", then just use "console-compute" VM as graphite nodes. This is for the case when other packs (e.g. Spark) that installed Graphite on "console-compute"

if hasConsole == true 
   graphiteNode = consoleNode
else 
   graphiteNode = nodes
end


graphiteNode.each do |n|
  unless n[:ciAttributes][:dns_record].eql? node[:ipaddress]
      remote_ip.push(n[:ciAttributes][:dns_record])
  end
end

local_carbon_hosts = Array.new
if node["cpu"]["total"] > 9
   (1..9).each do |i|
      local_carbon_hosts.push("127.0.0.1:710#{i}:0#{i}")
   end
   (10..node["cpu"]["total"]).each do |i|
      local_carbon_hosts.push("127.0.0.1:71#{i}:#{i}")
   end
else
   (1..node["cpu"]["total"]).each do |i|
      local_carbon_hosts.push("127.0.0.1:710#{i}:0#{i}")
   end
end

cookbook = node.app_name.downcase
Chef::Log.info("Cookbook is: #{cookbook}")
if cookbook.eql? "graphite"
  graphite_version = node.workorder.rfcCi.ciAttributes.version
else
  graphite_version = node['graphite']['version']
end

# local_settings.py
template "/opt/graphite/webapp/graphite/local_settings.py" do
    source "version_#{graphite_version}/local_settings-#{graphite_version}.py.erb"
    owner "root"
    group "root"
    mode "0755"
    variables(
	:cluster_members => remote_ip,
	:local_carbon_hosts => local_carbon_hosts
    )
end

# graphTemplates.conf
template "/opt/graphite/conf/graphTemplates.conf" do
    source "graphTemplates.conf.erb"
    owner "root"
    group "root"
    mode "0644"
end

# wsgi.py
cookbook_file "/opt/graphite/conf/wsgi.py" do
    source "wsgi.py"
    owner "root"
    group "root"
    mode "0755"
end
