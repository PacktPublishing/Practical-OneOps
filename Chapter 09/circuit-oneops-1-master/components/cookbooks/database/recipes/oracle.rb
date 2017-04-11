dbname = node.database.dbname
username = node.database.username
password = node.database.password
extra = node[:database][:extra].nil? ? "" : node[:database][:extra]

db_ddl_sql = "
SET TERM ON 
SET ECHO ON 
"

oracle_proc_count = (`ps auxwww|grep ora_ | wc -l`).chop.to_i

if oracle_proc_count < 10
  db_ddl_sql += "startup\n"
end

db_ddl_sql += "create user #{username} identified by #{password};
grant all privileges to #{username};
create directory dmpdir as '/opt/oracle';       
exit
"    

ruby_block 'setup sid and tnsnames' do
  block do
    # ddl sql execution - this is where the magic happens - creates database, user, grant for user to do anything, then startup the listener
    ::File.open('/tmp/db_ddl.sql', 'w') {|f| f.write(db_ddl_sql) }

    # create the db, user, grants and bring up the listener
    Chef::Log.info("create the db, user and grants...")    
    Chef::Log.info(`sudo su - oracle -c "source ~oracle/.bashrc ; sqlplus / as sysdba @/tmp/db_ddl.sql"`)

    if extra != ""
      extra += "\nexit\n"
      ::File.open('/tmp/db_extra.sql', 'w') {|f| f.write(extra) }
      Chef::Log.info("running extra sql: "+extra)    
      Chef::Log.info(`sudo su - oracle -c "source ~oracle/.bashrc ; sqlplus / as sysdba @/tmp/db_extra.sql"`)      
      exit_code = $?.to_i
      exit_with_error "exiting because exit_code from extra sql is: #{exit_code.to_s}" if exit_code != 0
    end
  end
end
