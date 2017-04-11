# need to have the ruby code in a ruby_block or it will be run before other chef dsl blocks

require 'aws/s3'

ruby_block 'dump and send to s3' do
  block do
    ts = `date "+%Y%m%d%H%M%S"`
    label = node.workorder.ci.ciName+"_"+ts.gsub("\n","")


    dump_file = "/tmp/#{label}-dump"
    cmd = "mysqldump --all-databases --flush-logs --master-data=2 --single-transaction > #{dump_file}"
    Chef::Log.info("running #{cmd} ...")
    `#{cmd}`
  
    bucket = node["customer_domain"]
    mime_type = "application/octet-stream"
  
    Chef::Log.info("connecting to s3...")
    AWS::S3::Base.establish_connection!(
      :access_key_id     => node.workorder.token.ciAttributes.key,
      :secret_access_key => node.workorder.token.ciAttributes.secret
    )  
  
    # dump file
    base_name = ::File.basename(dump_file)
    Chef::Log.info("Uploading #{dump_file} as '#{base_name}' to '#{bucket}'")
    AWS::S3::S3Object.store(
      base_name,
      ::File.open(data_tar),
      bucket,
      :content_type => mime_type
    )
      
    Chef::Log.info("Uploaded Done.")
  end
end
