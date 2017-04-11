node.set[:php][:build_options] = Mash.new(JSON.parse(node.workorder.rfcCi.ciAttributes.build_options))
node.set[:php][:conf_dir] = "#{node[:php][:build_options][:prefix]}/lib"
node.set[:php][:ext_conf_dir] = "#{node[:php][:conf_dir]}"

Chef::Log.debug("Build options: #{node[:php][:build_options].inspect}")

node.set[:php][:supported] = ["Apache"]
node.set[:php][:webserver] = node.workorder.payLoad.DependsOn.select { |o| node[:php][:supported].include? o['ciClassName'].split('.').last }.first

if node[:php][:webserver][:ciClassName]
  webserver_type = node[:php][:webserver][:ciClassName].split('.').last.downcase
  case webserver_type
  when "apache"
    case node[:php][:webserver][:ciAttributes][:install_type]
      when "build"
        build_options = Mash.new(JSON.parse(node[:php][:webserver][:ciAttributes][:build_options]))
        node.set[:php][:apache] = build_options[:prefix]
      # else
        # node[:php][:apache] = node[:apache][:dir]
      end
    node.set[:php][:build_options][:configure] = ["--with-apxs2=#{node[:php][:apache]}/bin/apxs",node[:php][:build_options][:configure]].join(" ")
  end
else
  Chef::Log.info("Webserver type not specified or not supported")
  exit 1
end


pkgs = value_for_platform(
    ["centos","redhat","fedora"] =>
        {"default" => %w{ kernel-devel gcc-c++ autoconf213 bzip2-devel libc-client-devel curl-devel freetype-devel gmp-devel libjpeg-devel krb5-devel libmcrypt-devel libpng-devel openssl-devel t1lib-devel }},
    [ "debian", "ubuntu" ] =>
        {"default" => %w{ build-essential autoconf2.13 libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev }},
    "default" => %w{ libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev }
  )

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

if node.workorder.rfcCi.rfcAction == "add" || (node.workorder.rfcCi.rfcAction == "update" && node.workorder.rfcCi.ciBaseAttributes.has_key?("build_options"))
  directory "#{node[:php][:build_options][:srcdir]}" do
    recursive true
    mode 0775
    action :create
  end

  # get php from source
  subversion "#{node[:php][:build_options][:srcdir]}" do
    repository "https://svn.php.net/repository/php/php-src/branches/#{node[:php][:build_options][:version]}"
    revision "HEAD"
    action :sync
  end

  autoconf = value_for_platform(
    ["centos","redhat","fedora"] =>
        {"default" => "autoconf-2.13"},
    [ "debian", "ubuntu" ] =>
        {"default" => "autoconf2.13"},
    "default" => "autoconf-2.13"
  )
  
  Chef::Log.debug("./configure --prefix=#{node[:php][:build_options][:prefix]} #{node[:php][:build_options][:configure]}")
  script "configure_php" do
    interpreter "bash"
    user 'root'
    group 'root'
    cwd "#{node[:php][:build_options][:srcdir]}"
    code <<-EOS
    PHP_AUTOCONF=#{autoconf} ./buildconf --force
    ./configure --quiet --prefix=#{node[:php][:build_options][:prefix]} #{node[:php][:build_options][:configure]}
    EOS
  end

  script "build_php" do
    interpreter "bash"
    user 'root'
    group 'root'
    cwd "#{node[:php][:build_options][:srcdir]}"
    code <<-EOS
    make --quiet clean
    make --quiet
    EOS
  end
    
  script "install_php" do
    interpreter "bash"
    user 'root'
    group 'root'
    cwd "#{node[:php][:build_options][:srcdir]}"
    code <<-EOS
    make --quiet install
    EOS
  end
else
  Chef::Log.info("Update called without new build options, skipping php build")
end


template "#{node[:php][:conf_dir]}/php.ini" do
  source "php.ini.erb"
  owner "root"
  group "root"
  mode "0644"
end

execute "generate-module-list" do
  command "#{node[:php][:apache]}/bin/module_conf_generate.pl #{node[:php][:apache]}/modules #{node[:php][:apache]}/mods-available"
end

template "#{node[:php][:apache]}/mods-available/php5.conf" do
  source "php5.conf.erb"
  #notifies :restart, resources(:service => "apache2")
  mode 0644
end

execute "a2enmod" do
  command "/usr/sbin/a2enmod php5"
end

file "#{node[:php][:apache]}/htdocs/index.php" do
  content "<?php phpinfo() ?>"
  mode 0644
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
