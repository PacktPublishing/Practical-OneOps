#
# postgresql::snapshot
# Walmart Labs
#

args = JSON.parse(node.workorder.arglist)    
local_path = args["local_path"] || '/tmp'
env_name = ""
if node.workorder.payLoad.has_key? "Environemnt"
  env_name = node.workorder.payLoad.Environment[0][:ciName]
end
ts = Time.now.strftime("%Y%m%d%H%M%S")
name = args["label"] || env_name
ci_name = node.workorder.ci.ciName

label = name + "_" + ci_name + "_" + ts
type = args["type"] || "local"

version = node.workorder.ci.ciAttributes["version"]
postgresql_conf = JSON.parse(node.workorder.ci.ciAttributes.postgresql_conf)
if postgresql_conf.has_key?('data_directory')
  data_dir = postgresql_conf['data_directory'].gsub(/\A'(.*)'\z/m,'\1')
else
  data_dir = "#{node[:postgresql][:data]}"
end

archive_dir = "#{data_dir}/archivedir"



Chef::Log.info("postgres::snapshot -- label: #{label} type: #{type}")

# cleanup archive dir
execute "rm -fr #{archive_dir}/*"

# in a block to sequence `` with execute resource
ruby_block 'start-backup' do
  block do    
    Chef::Log.info("starting snapshot with: pg_start_backup('#{label}')")
    `su postgres -c "psql -c \\";SELECT pg_start_backup('#{label}');\\""`        
  end
end

data_tar = "#{local_path}/snapshot-#{label}-data.tgz"
Chef::Log.info("tar to: "+data_tar)                

# default timeout of 3600 too small for prod
execute "tar -zcf #{data_tar} --exclude='archivedir' --exclude='postmaster.pid' --exclude='pg_xlog' *" do
  returns [0,1]
  timeout 7200
  cwd data_dir
end


# in a block to sequence `` with execute resource
ruby_block 'stop-backup' do
  block do                    
    Chef::Log.info("ending snapshot with: SELECT pg_stop_backup() ")
    `su postgres -c "psql -c \\";SELECT pg_stop_backup();\\""`  
  end
end

archive_tar = "#{local_path}/snapshot-#{label}-archivelog.tgz"
Chef::Log.info("tar to: "+archive_tar)

execute "tar -zcf #{archive_tar} *" do
  returns [0,1]
  cwd archive_dir
end

uber_tar = "#{local_path}/snapshot-#{label}.tar"

# commented out until logic to check size is added
#execute "tar -cf #{uber_tar} #{archive_tar} #{data_tar} ; rm -fr #{archive_tar} #{data_tar}" do
#  cwd local_path
#end

node.set[:tar] = uber_tar

if type != "local"  
  include_recipe "postgres::snapshot_upload_"+type
end
