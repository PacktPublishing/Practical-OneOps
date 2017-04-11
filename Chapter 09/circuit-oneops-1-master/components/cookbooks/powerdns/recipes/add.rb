# setup user and group
group "pdns" do
  gid 53
end

user "pdns" do
  comment "powerdns user"
  gid "pdns"
  uid 53
  home "/var/empty"
  supports :manage_home => false
  shell "/sbin/nologin"
end

# setup default backend
# TODO make backend server conditional based on attributes

directory "/etc/powerdns" do
  mode 0750
  owner "pdns"
  group "pdns"
end

template "/etc/powerdns/first-run" do
  source "first-run.erb"
  mode 0400
  owner "root"
  group "root"
  backup false
  variables(
    :powerdns_username => node[:powerdns][:dbuser],
    :powerdns_password => node[:powerdns][:dbpassword],
    :powerdns_database => node[:powerdns][:dbname]
  )
end

# install PowerDNS server
include_recipe "powerdns::server"

execute "first-run" do
  command "mysql -f < /etc/powerdns/first-run"
  notifies :reload, resources(:service => "pdns")
end

#include_recipe "powerdns::poweradmin"

