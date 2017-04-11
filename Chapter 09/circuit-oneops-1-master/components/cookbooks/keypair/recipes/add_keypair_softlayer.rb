#
require 'fog'

conn = node[:iaas_provider]

begin
  key = conn.key_pairs.get(node.kp_name)
rescue Excon::Errors::Error =>e
  puts "***RESPONSE= #{e.response.inspect}"
  case e.response[:status]
  when 404
    Chef::Log.info("keypair not found: #{node.kp_name}")
  else
    msg = e.message
    puts "***FAULT:FATAL= #{msg}"
    raise Excon::Errors::Error, msg
  end  
rescue Exception => e
  msg = e.message
  Chef::Log.fatal(e.inspect)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end

if key == nil
  key = conn.key_pairs.create(
      :label => node.kp_name, 
      :key => node.keypair.public
  )
  Chef::Log.info("import keypair: "+key.inspect)
else
  Chef::Log.info("existing keypair: #{key.inspect}")  
end

