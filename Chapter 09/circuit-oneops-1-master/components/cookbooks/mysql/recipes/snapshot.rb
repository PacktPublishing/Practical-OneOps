
# retrieving data
database_name = JSON.parse(node.workorder.arglist)["database_name"]
snapshot_path = JSON.parse(node.workorder.arglist)["snapshot_path"]

# exiting if attributes are empty
exit_with_error "database name and/or snapshot path cannot be empty" if database_name.empty? || snapshot_path.empty?

# checking if database exists
check_if_database_exists database_name

# creating database snaspshot
create_db_snapshot database_name, snapshot_path