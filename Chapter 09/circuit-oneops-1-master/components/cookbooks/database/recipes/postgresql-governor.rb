dbname = node.database.dbname
username = node.database.username
password = node.database.password
extra = ""
if node.database.has_key?("extra") 
  extra = node.database.extra
end

Chef::Log.info("Using database #{dbname} with user #{username}")

`ps -fu postgres | grep -v grep |grep receiver`
if $?.to_i == 0
  Chef::Log.info("receiver running... skip creating db because its a slave with streaming")
  return
else
  Chef::Log.info("receiver not running.")
end

bash "createuser" do
  code <<-EOH
    sudo -u postgres psql --host 127.0.0.1 -a -c "DROP DATABASE #{dbname}"
    sudo -u postgres psql --host 127.0.0.1 -a -c "DROP USER #{username}"
    sudo -u postgres psql --host 127.0.0.1 -a -c "CREATE USER #{username} WITH PASSWORD '#{password}'"
  EOH
end

bash "createdb" do
  # template0 is needed for UTF8 on ubuntu
  code <<-EOH
    sudo -u postgres psql --host 127.0.0.1 -a -c "CREATE DATABASE #{dbname} WITH ENCODING='UTF8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8' OWNER=#{username} CONNECTION LIMIT=-1 TEMPLATE template0;"
  EOH
end

if node.database.has_key?("dbserver")
  unless node.database.dbserver.ciAttributes[:version].to_f >= 9.0
    bash "plpgsql" do
      code <<-EOH
        sudo -u postgres psql --host 127.0.0.1 -d #{dbname} -a -c "CREATE LANGUAGE plpgsql;"
      EOH
    end
  end
end

unless extra.empty?
  bash "extra" do
    code <<-EOH
    sudo -u postgres psql --host 127.0.0.1 -d #{dbname} -a -c "#{extra}"
  EOH
  end
end
