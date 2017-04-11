# Cookbook Name:: postgresql-governor
# Recipe:: server_redhat
#
# Author : OneOps
# Apache License, Version 2.0

# Create a group and user like the package will.
# Otherwise the templates fail.

# TO-DO: check if still need this hack
# hack for centos-6.0
Chef::Log.info("Checking if the postgres group already exists")
`grep -E "postgres" /etc/group`
if $?.to_i == 0
  Chef::Log.info("Group exists, skipping add")
else
  Chef::Log.info("postgres group missing, adding postgres group") 
  `groupadd postgres -g 26 ; true`
  
  group "postgres" do
    # Workaround lack of option for -r and -o...
    group_name "-r -o postgres"
    not_if { Etc.getgrnam("postgres") }
    gid 26
  end
end

Chef::Log.info("Checking if the postgres user already exists")
    `grep -E "postgres" /etc/passwd`
if $?.to_i == 0
    Chef::Log.info("User exists, skipping add")
else
    Chef::Log.info("postgres user missing, adding postgres user") 
    `useradd postgres -g postgres -u 26 -r -d /var/lib/pgsql -m -s /bin/bash ; true`
    
    user "postgres" do
      # Workaround lack of option for -M and -n...
      username "-M -n postgres"
      not_if { Etc.getpwnam("postgres") }
      shell "/bin/bash"
      comment "PostgreSQL Server"
      home "/var/lib/pgsql"
      gid "postgres"
      system true
      uid 26
      supports :non_unique => true
    end
end

misc_proxy = ENV["misc_proxy"]

version = node['postgresql-governor']['version']
version_short = version.split('.').join

if ["redhat","centos"].include?(node.platform) &&
  node.platform_version.to_f > 6 && misc_proxy.nil?
  # example: yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-2.noarch.rpm
  execute "rpm -ivh https://download.postgresql.org/pub/repos/yum/#{version}/redhat/rhel-7-x86_64/pgdg-#{node.platform}#{version_short}-#{version}-2.noarch.rpm" do
    returns [0,1]
  end
end

package "postgresql" do
  case node.platform
  when "redhat","centos"
    package_name "postgresql#{version_short}"
  else
    package_name "postgresql"
  end
end

case node.platform
when "redhat","centos"
  package "postgresql#{version_short}-server"
  package "postgresql#{version_short}-contrib"
  package "postgresql#{version_short}-devel"
  package "postgresql#{version_short}-libs"
when "fedora","suse"
  package "postgresql-server"
  package "postgresql-contrib"
  package "postgresql-devel"
  package "postgresql-libs"
end
