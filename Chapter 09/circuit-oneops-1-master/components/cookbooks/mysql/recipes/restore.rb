
# retrieving data
database_name = JSON.parse(node.workorder.arglist)["database_name"]
snapshot_path = JSON.parse(node.workorder.arglist)["snapshot_path"]

# exiting if attributes are empty or snapshot not found
exit_with_error "database name and/or snapshot path cannot be empty" if database_name.empty? || snapshot_path.empty?
exit_with_error "unable to find snapshot #{snapshot_path}" if !File.exists?(snapshot_path)

# checking if database exists
check_if_database_exists database_name

# restoring database from snapshot
restore_db_from_snapshot database_name, snapshot_path