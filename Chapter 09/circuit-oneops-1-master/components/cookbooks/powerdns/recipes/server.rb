# stop and disable named / bind 
bind_package_name = value_for_platform(
  [ "debian","ubuntu" ] => {"default" => "bind9"}, 
  ["fedora","redhat","centos"] => {"default" => "bind" },
              "default" => "named"
)

service bind_package_name do
  supports :status => true
  action [ :stop, :disable ]
end


service "pdns" do
    supports :restart => true, :status => true, :reload => true
      action :nothing
end

case node[:platform]
when "redhat","centos","fedora"
  execute "install_powerdns_from_rpm" do
    command "cd /tmp;rpm -Uvh http://downloads.powerdns.com/releases/rpm/pdns-static-2.9.22-1.i386.rpm"
    not_if { FileTest.exists?("/usr/sbin/pdns_server") }
  end
when "ubuntu","debian"
  %w(pdns-server pdns-recursor pdns-backend-mysql pdns-backend-pipe pdns-backend-sqlite3 pdns-backend-sqlite).each do |p|
    package "#{p}" do
      action :install
    end
  end
end

template "/etc/powerdns/pdns.conf" do
  source "pdns.conf.erb"
  mode 0440
  owner "pdns"
  group "pdns"
  backup false
  variables(
    :allow_axfr_ips => node[:powerdns][:allow_axfr_ips],
    :allow_recursion => node[:powerdns][:allow_recursion],
    :default_soa_name => node[:powerdns][:soa_name],
    :default_ttl => node[:powerdns][:ttl],
    :distributor_threads => node[:powerdns][:threads],
    :powerdns_address => node[:powerdns][:dbserver],
    :powerdns_username => node[:powerdns][:dbuser],
    :powerdns_password => node[:powerdns][:dbpassword],
    :powerdns_database => node[:powerdns][:dbname]
  )
  notifies :reload, resources(:service => "pdns")
end

