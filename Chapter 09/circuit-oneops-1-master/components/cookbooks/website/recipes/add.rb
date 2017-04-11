node.set[:website][:name] = node.workorder.payLoad.RealizedAs.first[:ciName]
Chef::Log.info("Configuring website #{node[:website][:name]}")

node.set[:website][:supported] = ["Apache","Nginx"]
node.set[:website][:webserver] = node.workorder.payLoad.DependsOn.select { |o| node[:website][:supported].include? o['ciClassName'].split('.').last }.first

if node[:website][:webserver][:ciClassName]
  webserver_type = node[:website][:webserver][:ciClassName].split('.').last.downcase
  Chef::Log.info("Webserver type #{webserver_type} - running recipe website::#{webserver_type}")
  include_recipe "website::#{webserver_type}"
else
  Chef::Log.info("Webserver type not specified or not supported")
  exit 1
end