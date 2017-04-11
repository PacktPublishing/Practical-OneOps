#
# supports openstack keypair::add
#
require 'fog'

# create if doesn't exist  
# openstack doesnt like '.'
node.set["kp_name"] = node.kp_name.gsub(".","-")

conn = node[:iaas_provider]

key = conn.key_pairs.get(node.kp_name)
if key == nil
  begin
    key = conn.key_pairs.create(
        :name => node.kp_name, 
        :public_key => node.keypair.public
    )
    Chef::Log.info("import keypair: "+key.inspect)
   rescue Excon::Errors::Error =>e
    msg=""
     case e.response[:body]
     when /\"code\": 413/
      msg = JSON.parse(e.response[:body])['overLimit']['message']
      Chef::Log.error("error response body :: #{msg}")
      puts "***FAULT:FATAL= openstack quota exceeded."
      raise Excon::Errors::RequestEntityTooLarge, msg
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
else
  Chef::Log.info("existing keypair: #{key.inspect}")  
end

