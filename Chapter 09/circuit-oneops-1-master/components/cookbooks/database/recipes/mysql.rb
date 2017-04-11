dbname = node.database.dbname
username = node.database.username
password = node.database.password
extra = ""
if node.database.has_key?("extra") 
  extra = node.database.extra
end

`/usr/bin/mysql -u root -D #{dbname} -e status`

execute_command("/usr/bin/mysql -u root -e 'CREATE DATABASE #{dbname};'") if !$?.success?

execute_command("/usr/bin/mysql -u root -e 'GRANT ALL PRIVILEGES ON #{dbname}.* TO \"#{username}\"@\"%\" IDENTIFIED BY \"#{password}\"; FLUSH PRIVILEGES;'")

execute_command("echo -e '#{extra}' > /tmp/#{dbname}_extra.sql")

execute_command("/usr/bin/mysql -u root -D #{dbname} < /tmp/#{dbname}_extra.sql")
