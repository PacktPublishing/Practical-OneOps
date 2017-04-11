include_recipe "postgresql::add"

# reload to get updated pg_hba.conf
if node.platform_family  == 'rhel'
  service "postgresql-#{node.postgresql.version}" do
    pattern "postgres: writer"
    action :reload
  end
else
  service "postgresql" do
    service_name "postgresql"
    pattern "postgres: writer"
    action :reload
  end 
end
