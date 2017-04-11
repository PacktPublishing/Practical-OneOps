# create the DB and user
require 'json'

payload = node.workorder.payLoad
depends_on = Array.new
size = 0
db_type = ""

if payload.has_key?('DependsOn')
  depends_on = payload.DependsOn.select { |db| ['Mssql','Mysql','Postgresql','Oracle'].include?(db['ciClassName'].split('.').last) }
  size = depends_on.group_by{ |db| db['ciName'] }.size
end

case 
when size == 0
  pack_name = node.workorder.box.ciAttributes["pack"]
  if pack_name =~ /postgres|oracle|mssql|mysql/
    db_type = pack_name
    Chef::Log.info("Using db_type: "+db_type+ " via box")
  else
    exit_with_error "Unable to find a DB server information in the request. Exiting."
  end
when size == 1
  dbserver = depends_on.first
  node.default[:database][:dbserver] = dbserver
  Chef::Log.info("Using dbserver #{dbserver['ciName']}")
  db_type = dbserver['ciClassName'].split('.').last.downcase
when size > 1
  exit_with_error "Multiple DB servers found. Exiting due to ambigous data."
end

include_recipe "database::#{db_type}"
pretty_json = JSON.pretty_generate(node)
::File.open('/opt/oneops/database_node', 'w') {|f| f.write( pretty_json ) }
