node.set[:waf][:supported] = ["Apache"]
node.set[:waf][:webserver] = node.workorder.payLoad.DependsOn.select { |o| node[:waf][:supported].include? o['ciClassName'].split('.').last }.first

if node[:waf][:webserver][:ciClassName]
  webserver_type = node[:waf][:webserver][:ciClassName].split('.').last.downcase
  Chef::Log.info("Webserver type #{webserver_type} - running recipe waf::#{webserver_type}")
  include_recipe "waf::#{webserver_type}"
else
  Chef::Log.info("Webserver type not specified or not supported")
  exit 1
end
