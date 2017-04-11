template "/etc/nginx/sites-available/#{node[:website][:name]}" do
  source "nginx-site.erb"
  owner "root"
  group "root"
  mode 0644
end

# ssl
if node[:website].has_key?('ssl') && node[:website][:ssl] == "on"
  file "#{node[:website][:dir]}/ssl/#{node[:website][:name]}.crt" do
    content node[:website][:sslcert]
  end
  file "#{node[:website][:dir]}/ssl/#{node[:website][:name]}.key" do
    content node[:website][:sslcertkey]
  end
end

execute "enable" do
  command "/usr/sbin/nxensite #{node[:website][:name]}"
end

service "nginx" do
  action :restart
end