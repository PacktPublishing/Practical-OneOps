case node[:website][:webserver][:ciAttributes][:install_type]
when "build"
  build_options = Mash.new(JSON.parse(node[:website][:webserver][:ciAttributes][:build_options]))
  node.set[:website][:dir] = build_options[:prefix]
  node.set[:website][:root] = "#{node[:website][:dir]}/htdocs" if node[:website][:root].empty?
else
  node.set[:website][:dir] = node[:apache][:dir]
  node.set[:website][:root] = '/var/www' if node[:website][:root].empty?
end


directory "#{node[:website][:root]}" do
  recursive true
  action :create
  not_if { File.exists?(node[:website][:root]) }
end
    
template "#{node[:website][:dir]}/sites-available/#{node[:website][:name]}.conf" do
  source "apache-site.erb"
  owner "root"
  group "root"
  mode 0644
end

execute "a2ensite" do
  command "/usr/sbin/a2ensite #{node[:website][:name]}.conf"
  not_if do ::File.symlink?("#{node[:website][:dir]}/sites-enabled/#{node[:website][:name]}.conf") end
  only_if do ::File.exists?("#{node[:website][:dir]}/sites-available/#{node[:website][:name]}.conf") end
end

# ssl
if node[:website].has_key?('ssl') && node[:website][:ssl] == "on"
  file "#{node[:website][:dir]}/ssl/#{node[:website][:name]}.crt" do
    content node[:website][:sslcert] 
  end
  file "#{node[:website][:dir]}/ssl/#{node[:website][:name]}.key" do
    content node[:website][:sslcertkey] 
  end
  if node[:website].has_key?('sslcacertkey') && !node[:website][:sslcacertkey].empty?
    file "#{node[:website][:dir]}/ssl/#{node[:website][:name]}.ca" do
      content node[:website][:sslcacertkey] 
    end
  end
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
end