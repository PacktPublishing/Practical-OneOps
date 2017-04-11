
template "/opt/nagios/libexec/check_sql_pg.rb" do
  source "check_sql_pg.erb"
  owner "oneops"
  group "oneops"
  mode 0755
end

template "/etc/nagios3/pg_stats.yaml" do
  source "pg_stats.yaml.erb"
  mode 0644
end

template "#{node[:postgresql][:dir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
end

directory "#{node[:postgresql][:dir]}/archivedir" do
  owner "postgres"
  group "postgres"
  recursive true
  action :create
end