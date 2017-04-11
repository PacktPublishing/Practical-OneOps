case node[:waf][:webserver][:ciAttributes][:install_type]
when "build"
  build_options = Mash.new(JSON.parse(node[:waf][:webserver][:ciAttributes][:build_options]))
  node.set[:waf][:apache] = build_options[:prefix]
else
  node.set[:waf][:apache] = node[:apache][:dir]
end

# pre-requisite libraries
case node[:platform]
when "centos","redhat","fedora","suse"
  package_list = ["pcre-devel","expat-devel","lua","lua-socket"]
when "debian","ubuntu"
  package_list = ["libpcre3-dev","libexpat-dev","lua5.1","luasocket"]
end

package_list.each do |name|
  package "#{name}"
end


remote_file "/usr/local/src/modsecurity-apache_#{node[:waf][:version]}.tar.gz" do
  source "http://www.modsecurity.org/download/modsecurity-apache_#{node[:waf][:version]}.tar.gz"
  action :create
  not_if do ::File.exists? "/usr/local/src/modsecurity-apache_#{node[:waf][:version]}.tar.gz" end
end

script "build_modsecurity" do
  interpreter "bash"
  user 'root'
  group 'root'
  cwd "/usr/local/src"
  code <<-EOS
  tar zxvf modsecurity-apache_#{node[:waf][:version]}.tar.gz
  cd modsecurity-apache_#{node[:waf][:version]}
  ./configure --quiet --with-apxs=#{node[:waf][:apache]}/bin/apxs \
                      --with-apr=#{node[:waf][:apache]}/bin/apr-1-config \
                      --with-apu=#{node[:waf][:apache]}/bin/apu-1-config
  make --quiet clean
  make --quiet
  make --quiet install
  EOS
end

execute "generate-module-list" do
  command "#{node[:waf][:apache]}/bin/module_conf_generate.pl #{node[:waf][:apache]}/modules #{node[:waf][:apache]}/mods-available"
end

execute "a2enmod" do
  command "/usr/sbin/a2enmod security2"
end

service "httpd" do
  action :restart
end
