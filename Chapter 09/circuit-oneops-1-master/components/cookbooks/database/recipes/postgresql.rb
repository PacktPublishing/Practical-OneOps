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

ruby_block "createuser" do
  block do
    execute_command("sudo -u postgres psql -a -c \"CREATE USER #{username} WITH PASSWORD '#{password}'\"")
  end
end

bash "createdb" do
  # template0 is needed for UTF8 on ubuntu
  code <<-EOH
    sudo -u postgres psql -a -c "CREATE DATABASE #{dbname} WITH ENCODING='UTF8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8' OWNER=#{username} CONNECTION LIMIT=-1 TEMPLATE template0;"
  EOH
end

if node.database.has_key?("dbserver")
  unless node.database.dbserver.ciAttributes[:version].to_f >= 9.0
    ruby_block "plpgsql" do
      block do
        execute_command("sudo -u postgres psql -d #{dbname} -a -c \"CREATE LANGUAGE plpgsql;\"")
      end
    end
  end
end

unless extra.empty?
  ruby_block "Additional DB statements" do
    block do
      execute_command("sudo -u postgres psql -d #{dbname} -a -c \"#{extra}\"")
    end
  end
end
