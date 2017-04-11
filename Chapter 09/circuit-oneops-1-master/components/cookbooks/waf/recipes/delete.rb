node.set[:waf][:name] = node.workorder.payLoad.RealizedAs.first[:ciName]
Chef::Log.info("Deleting waf #{node[:waf][:name]}")

node.set[:waf][:supported] = ["Apache"]
node.set[:waf][:webserver] = node.workorder.payLoad.DependsOn.select { |o| node[:waf][:supported].include? o['ciClassName'].split('.').last }.first

if node[:waf][:webserver][:ciClassName]
  webserver_type = node[:waf][:webserver][:ciClassName].split('.').last.downcase
  case webserver_type
  when "apache"
    execute "a2dismod security2" do
      command "/usr/sbin/a2dismod security2"
    end
    service "httpd" do
      action :restart
    end
  end
else
  Chef::Log.info("Webserver type not specified or not supported")
  exit 1
end

