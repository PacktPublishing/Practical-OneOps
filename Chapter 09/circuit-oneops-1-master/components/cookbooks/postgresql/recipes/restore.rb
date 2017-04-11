# need to have the ruby code in a ruby_block or it will be run before other chef dsl blocks

require 'rubygems'
require 'aws/s3'
require 'aws/s3/object'
require 'json'

args = ::JSON.parse(node.workorder.arglist)
label = args["label"] || args["snapshot"]   


service 'postgresql-9.1' do
  action :stop
  pattern 'postgres:'
  only_if { label =~ /snapshot-/ }
end

ruby_block 'restore' do
  block do

    Chef::Log.info("connecting to s3...")
    ::AWS::S3::Base.establish_connection!(
      :access_key_id     => node.workorder.token.ciAttributes.key,
      :secret_access_key => node.workorder.token.ciAttributes.secret
    )

    bucket = args["bucket"]
    Chef::Log.info("downloading label: #{label} from s3 bucket: #{bucket}...")

    if label =~ /snapshot-/
      `pgrep -f postgres:`
      if $? == 0
         Chef::Log.info("postgresql still running after stop. exiting before restore.")
      end
      
      data_tar = "#{label}-data.tgz"
      archive_tar = "#{label}-archivelog.tgz"
  
      open('/tmp/'+data_tar, 'w') do |file|
        ::AWS::S3::S3Object.stream(data_tar, bucket) do |chunk|
          file.write chunk
        end
      end
      open('/tmp/'+archive_tar, 'w') do |file|
        ::AWS::S3::S3Object.stream(archive_tar, bucket) do |chunk|
          file.write chunk
        end
      end
  
      postgresql_conf = JSON.parse(node.postgresql.postgresql_conf)
      if postgresql_conf.has_key?('data_directory')
        data_dir = postgresql_conf['data_directory'].gsub(/\A'(.*)'\z/m,'\1')
      else
        data_dir = "#{node[:postgresql][:data]}"
      end
      Chef::Log.info("Restoring data files to directory: "+data_dir)
          
      restore_dir = "#{node[:postgresql][:dir]}/restoredir"
      Chef::Log.info("Restoring archive logs to directory: "+restore_dir)
      
      `rm -fr #{data_dir}/*`
      `rm -fr #{restore_dir}/*`
      ::Dir.chdir(data_dir)
      `tar -zxf /tmp/#{data_tar}`
      `echo "restore_command = 'cp #{restore_dir}/%f %p'" > recovery.conf`
      `chown postgres:postgres recovery.conf`
      `mkdir -p #{data_dir}/archivedir`
      `mkdir -p #{data_dir}/pg_xlog/archive_status`
      `chown -R postgres:postgres #{data_dir}/pg_xlog`
  
      `mkdir -p #{restore_dir}`
      ::Dir.chdir(restore_dir)
      `tar -zxf /tmp/#{archive_tar}`
    else

      dump_file = "#{label}-dump"
      open('/tmp/'+dump_file, 'w') do |file|
        ::AWS::S3::S3Object.stream(dump_file, bucket) do |chunk|
          file.write chunk
        end
      end
      
      Chef::Log.info("Restoring from dump file: "+dump_file)
      `su postgres -c "psql -f /tmp/#{dump_file} postgres"`      
    end

  end
end

service 'postgresql-9.1' do
  action :start
  pattern 'postgres:'
  only_if { label =~ /snapshot-/ }
end

