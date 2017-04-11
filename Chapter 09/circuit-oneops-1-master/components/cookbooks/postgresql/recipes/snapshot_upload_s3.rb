# need to have the ruby code in a ruby_block or it will be run before other chef dsl blocks

require 'aws/s3'

Chef::Log.info("connecting to s3...")
AWS::S3::Base.establish_connection!(
  :access_key_id     => node.workorder.services.s3.ciAttributes.key,
  :secret_access_key => node.workorder.services.s3.ciAttributes.secret
)  


args = JSON.parse(node.workorder.arglist)    
bucket = args["bucket"] || 'snapshot'

begin
  AWS::S3::Bucket.create(bucket)
rescue Exception => e      
end

tar = node[:tar]

base_name = ::File.basename(tar)
Chef::Log.info("Uploading #{tar} as '#{base_name}' to '#{bucket}'")
AWS::S3::S3Object.store(
  base_name,
  ::File.open(tar),
  bucket,
  :content_type => "application/octet-stream"
)

Chef::Log.info("Uploaded Done.")
