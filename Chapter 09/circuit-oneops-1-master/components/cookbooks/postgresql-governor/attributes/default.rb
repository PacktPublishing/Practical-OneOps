# Cookbook Name:: postgresql-governor
#
# Author : OneOps
# Apache License, Version 2.0

default['postgresql-governor'][:governor_download] = 'https://github.com/compose/governor/archive/master.zip'
default['postgresql-governor'][:governor_systemd_file] = '/usr/lib/systemd/system/governor.service'
default['postgresql-governor'][:haproxy_status_systemd_file] = '/usr/lib/systemd/system/haproxy_status.service'
default['postgresql-governor'][:governor_home] = '/var/lib/pgsql/governor-master'

# TO-DO: check if still need to do the following
case platform
when "debian"

  if platform_version.to_f == 5.0
    default['postgresql-governor'][:version] = "8.3"
  elsif platform_version =~ /.*sid/
    default['postgresql-governor'][:version] = "8.4"
  end

  set['postgresql-governor'][:dir] = "/etc/postgresql/#{node['postgresql-governor'][:version]}/main"
  set['postgresql-governor'][:data] = "/var/lib/postgresql/#{node['postgresql-governor'][:version]}/main"

when "ubuntu"

  if platform_version.to_f < 11.10
    default['postgresql-governor'][:version] = "8.4"
  else
    default['postgresql-governor'][:version] = "9.2"
  end

  set['postgresql-governor'][:dir] = "/etc/postgresql/#{node['postgresql-governor'][:version]}/main"
  set['postgresql-governor'][:data] = "/var/lib/postgresql/#{node['postgresql-governor'][:version]}/main"

when "fedora"

  if platform_version.to_f <= 12
    default['postgresql-governor'][:version] = "8.3"
  else
    default['postgresql-governor'][:version] = "8.4"
  end

  set['postgresql-governor'][:dir] = "/var/lib/pgsql/data"
  set['postgresql-governor'][:data] = "/var/lib/pgsql/data"

when "redhat","centos"

  default['postgresql-governor'][:version] = "9.4"
  set['postgresql-governor'][:dir] = "/var/lib/pgsql/#{node['postgresql-governor'][:version]}/data"
  set['postgresql-governor'][:data] = "/var/lib/pgsql/#{node['postgresql-governor'][:version]}/data"

when "suse"

  if platform_version.to_f <= 11.1
    default['postgresql-governor'][:version] = "8.3"
  else
    default['postgresql-governor'][:version] = "8.4"
  end

  set['postgresql-governor'][:dir] = "/var/lib/pgsql/data"

else
  default['postgresql-governor'][:version] = "8.4"
  set['postgresql-governor'][:dir]            = "/etc/postgresql/#{node['postgresql-governor'][:version]}/main"
  set['postgresql-governor'][:data] = "/var/lib/postgresql/#{node['postgresql-governor'][:version]}/main"
end
