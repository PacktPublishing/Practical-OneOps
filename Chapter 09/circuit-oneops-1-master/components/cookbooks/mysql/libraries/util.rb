
def exit_with_error(msg)
	Chef::Log.error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end

def check_if_database_exists(database_name)
	Chef::Log.info("checking if #{database_name} database exists")
	output = `mysql -e 'use #{database_name}' 2>&1`
	exit_with_error "unable to find #{database_name}. #{output.gsub(/\n+/, ".")}" if $?.exitstatus != 0
	Chef::Log.info("successfully able to find database")
end

def create_db_snapshot(database_name, snapshot_path)
	`mkdir -p $(dirname #{snapshot_path})`
	Chef::Log.info("creating snapshot #{snapshot_path}")
	output = `mysqldump #{database_name} 2>&1 > #{snapshot_path}`
	exit_with_error "unable to create snapshot. #{output.gsub(/\n+/, ".")}" if $?.exitstatus != 0
	Chef::Log.info("successfully able to create snapshot")
end

def restore_db_from_snapshot(database_name, snapshot_path)
	Chef::Log.info("restoring #{database_name} database from snapshot #{snapshot_path}")
	output = `mysql --one-database #{database_name} < #{snapshot_path}`
	exit_with_error "unable to restore from snapshot. #{output.gsub(/\n+/, ".")}" if $?.exitstatus != 0
	Chef::Log.info("successfully able to restore from snapshot")
end
