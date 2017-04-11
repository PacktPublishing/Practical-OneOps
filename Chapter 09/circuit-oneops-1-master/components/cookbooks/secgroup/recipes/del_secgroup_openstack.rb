#
# supports openstack secgroup::delete
#
conn = node[:iaas_provider]

node.set["secgroup_name"] = node.secgroup_name.gsub(".","-")
sg = conn.security_groups.get node.secgroup.group_id

# remove security group from the all the local compute instances
ruby_block 'remove security groups' do
  block do
    
    ci = node.workorder.rfcCi
    cloud_index = ci[:ciName].split('-').reverse[1].to_i
    # get only local computes in the cloud
    computes = node.workorder.payLoad.has_key?('RequiresComputes')? 
      node.workorder.payLoad.RequiresComputes.reject{ |c| c[:ciName].split('-').reverse[1].to_i != cloud_index } : {}

    computes.each do |cm|
      server = conn.servers.get(cm["ciAttributes"]["instance_id"])
      unless server.nil?
        begin
          res = conn.remove_security_group(server.id,node.secgroup.group_id)
          Chef::Log.info("remove secgroup response for sg: #{node.secgroup_name} #{node.secgroup.group_id}: "+res.inspect)
        rescue Excon::Errors::Error =>e
         msg=""
         case e.response[:body]
         when /\"code\": 400/
          msg = JSON.parse(e.response[:body])['badRequest']['message']
          Chef::Log.error("error response body :: #{msg}")
          puts "***FAULT:FATAL=OpenStack API error: #{msg}"
          raise Excon::Errors::BadRequest, msg
         else
          msg = e.message
          puts "***FAULT:FATAL=OpenStack API error: #{msg}"
          raise Excon::Errors::Error, msg
         end  
        rescue Exception => e
           msg = e.message
           if msg =~ /404/
             Chef::Log.info("secgroup already removed from #{server.id}")
             next
           end           
           Chef::Log.fatal(e.inspect)
           puts "***FAULT:FATAL= #{msg}"
           e = Exception.new("no backtrace")
           e.set_backtrace("")
           raise e
        end    
      end
      
    end
    
    # delete if exists  
    if sg.nil?
      Chef::Log.info("already deleted secgroup: #{node.secgroup_name} #{node.secgroup.group_id}")  
    else
      begin
        sg.destroy
        Chef::Log.info("deleted secgroup: #{node.secgroup.group_name} #{node.secgroup.group_id}")
      rescue Excon::Error => e                
        bad_request = JSON.parse(e.response[:body])['badRequest']
          
        if bad_request.has_key?('code') && bad_request['code'] == 400
          msg = bad_request['message']
        else
          msg = e.response[:body]
        end
        puts "***FAULT:FATAL=#{msg}"
        e.set_backtrace("")
        raise e, msg
      rescue Exception => e      
        puts "***FAULT:FATAL=#{e.message}"
        e.set_backtrace("")
        raise e, msg
           
      end 
    end
    
  end  
end