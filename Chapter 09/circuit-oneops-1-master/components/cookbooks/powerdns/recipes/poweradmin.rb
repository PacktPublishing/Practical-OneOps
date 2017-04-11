#
# Cookbook Name:: powerdns
# Recipe:: default
#
# Copyright 2009, Adapp, Inc.
#

remote_file "/usr/src/poweradmin-2.1.3.tgz" do
  source "https://www.poweradmin.org/download/poweradmin-2.1.3.tgz"
  owner "root"
  group "root"
  mode "0644"
  not_if { FileTest.exists?("/usr/src/poweradmin-2.1.3.tgz") }
end

directory "/var/www" do
  owner "www-data"
  group "www-data"
  mode "0755"
end

execute "un-archive poweradmin" do
  command "cd /var/www;tar zxfv /usr/src/poweradmin-2.1.3.tgz"
  not_if { FileTest.exists?("/var/www/poweradmin-2.1.3/index.html") }
end

template "/var/www/poweradmin-2.1.3/inc/config.inc.php" do
  source "config.inc.php.erb"
  owner "www-data"
  group "www-data"
  mode "0755"
  backup false
  variables(
    :powerdns_address => node[:powerdns][:server][:address],
    :powerdns_username => node[:powerdns][:server][:username],
    :powerdns_password => node[:powerdns][:server][:password],
    :powerdns_database => node[:powerdns][:server][:database],
    :powerdns_ns1 => node[:powerdns][:server][:ns1],
    :powerdns_ns2 => node[:powerdns][:server][:ns2],
    :powerdns_hostmaster => node[:powerdns][:server][:hostmaster]
  )
end

link "/var/www/poweradmin-2.1.3" do
  to "/var/www/poweradmin"
end


