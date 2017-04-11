
if node.php.version != "default"
  package "php-common" do
    action :remove
  end

  cloud_name = node[:workorder][:cloud][:ciName]
  if node[:workorder][:services].has_key? "mirror"
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  else
    exit_with_error "Cloud Mirror Service has not been defined"
  end
  php_source = mirrors['php']
  if php_source.nil?
    exit_with_error "php source repository has not beed defined in cloud mirror service"
  else
    Chef::Log.info("php source repository has been defined in cloud mirror service #{php_source}")
  end

  template "/etc/yum.repos.d/phpwebtatic.repo" do
    source "phpwebtatic.repo.erb"
    owner "root"
    group "root"
    mode "0644"
    variables({
      :php_source => php_source,
      :php_version => node.php.version
    })
  end

  pkgs = ["php55w-common", "php55w-pdo", "php55w-cli", "php55w-mbstring", "php55w-mysql", "php55w-ldap", "php55w", "php55w-opcache", "nagios", "nagios-devel"]
  pkgs.each do |pkg|
    package pkg do
      action :install
    end
  end
else
  pkgs = value_for_platform(
    [ "centos", "redhat", "fedora" ] => {
      "default" => %w{ php php-devel wget php-cli php-pear spawn-fcgi}
    },
    [ "debian", "ubuntu" ] => {
      "default" => %w{ php5-cgi php5 php5-dev php5-cli php-pear libapache2-mod-php5 }
    },
    "default" => %w{ php5-cgi php5 php5-dev php5-cli php-pear }
  )

  pkgs.each do |pkg|
    package pkg do
      action :install
    end
  end

  include_recipe "php::module_sqlite3"
  include_recipe "php::module_mysql"
  include_recipe "php::module_pgsql"
  include_recipe "php::module_memcache"
  include_recipe "php::module_ldap"
  include_recipe "php::module_gd"
  #include_recipe "php::module_fpdf"
  # removed due to ubuntu 11.10+ :
  # [2012-10-28T18:29:15+00:00] FATAL: Chef::Exceptions::Package: No candidate version available for php5-fileinfo
  #include_recipe "php::module_fileinfo"
  include_recipe "php::module_curl"
  include_recipe "php::module_apc"

  # update the main channels
  php_pear_channel 'pear.php.net' do
    action :update
  end

  php_pear_channel 'pecl.php.net' do
    action :update
  end
end

template "#{node['php']['conf_dir']}/php.ini" do
  source "php.ini.erb"
  owner "root"
  group "root"
  mode "0644"
end

# fcgi
if node[:php][:fcgi] == 'true'
  template "/etc/init.d/php-fastcgi" do
    backup false
    source "initd-php-fastcgi.erb"
    owner "root"
    group "root"
    mode "0755"
  end
  
  template "/etc/default/php-fastcgi" do
    source "php-fastcgi.erb"
    owner "root"
    group "root"
    mode "0644"
  end
  
  template "/usr/bin/php-fastcgi" do
    source "bin-php-fastcgi.erb"
    owner "root"
    group "root"
    mode "0644"  
    only_if { node.platform == "fedora" }
  end
  
  ruby_block "fedora hack" do
    block do
      if node.platform == "fedora"
        `wget -O php-fastcgi-rpm.sh http://library.linode.com/assets/647-php-fastcgi-rpm.sh`
        `mv -f php-fastcgi-rpm.sh /usr/bin/php-fastcgi`
        `chmod +x /usr/bin/php-fastcgi`
      end
    end
  end
  #      `wget -O php-fastcgi-init-rpm.sh http://library.linode.com/assets/648-php-fastcgi-init-rpm.sh`
  #      `mv -f php-fastcgi-init-rpm.sh /etc/rc.d/init.d/php-fastcgi`
  #      `chmod +x /etc/rc.d/init.d/php-fastcgi`
  
  service "php-fastcgi" do
    supports :restart => true, :reload => true, :start => true, :stop => true
    action [:enable, :start]
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
