node.default[:website][:name] = node.workorder.payLoad.RealizedAs.first[:ciName]
Chef::Log.info("Deleting website #{node[:website][:name]}")

node.default[:website][:supported] = ["Apache","Nginx"]
node.default[:website][:webserver] = node.workorder.payLoad.DependsOn.select { |o| node[:website][:supported].include? o['ciClassName'].split('.').last }.first

if node[:website][:webserver][:ciClassName]
  webserver_type = node[:website][:webserver][:ciClassName].split('.').last.downcase
  case webserver_type
  when "apache"
    execute "a2dissite" do
      command "/usr/sbin/a2dissite #{node[:website][:name]}.conf"
      ignore_failure true
    end
    service "apache2" do
      case node[:platform]
      when "centos","redhat","fedora","suse"
        service_name "httpd"
      when "debian","ubuntu"
        service_name "apache2"
      when "arch"
        service_name "httpd"
      end
      action :restart
      ignore_failure true
    end
  when "nginx"
    # returns 1 if doesnt exist/already disabled
    execute "disable" do
      command "/usr/sbin/nxdissite #{node[:website][:name]}"
      returns [0,1]
    end   
    service "nginx" do
      action :restart
    end
  end
else
  Chef::Log.info("Webserver type not specified or not supported")
  exit 1
end

