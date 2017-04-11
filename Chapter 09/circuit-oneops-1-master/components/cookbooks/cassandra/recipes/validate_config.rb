#
# cassandra::validate_config
#

immutable_attrs = [
  "data_file_directories",
  "saved_caches_directory",
  "commitlog_directory"
]

# check for changes - previous value is in ciBaseAttributes
if node.workorder.rfcCi.has_key?("ciBaseAttributes") &&
   node.workorder.rfcCi.ciBaseAttributes.has_key?("config_directives")

  old_cfg = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.config_directives)
  cfg = JSON.parse(node.workorder.rfcCi.ciAttributes.config_directives)
  
  immutable_attrs.each do |immutable_attr|
    if ( cfg.has_key?(immutable_attr) && old_cfg.has_key?(immutable_attr)  &&  # changed
         cfg[immutable_attr] != old_cfg[immutable_attr]) ||
       (!cfg.has_key?(immutable_attr) && old_cfg.has_key?(immutable_attr)) ||  # removed
       (node.workorder.rfcCi.rfcAction == "update" &&
        cfg.has_key?(immutable_attr) && !old_cfg.has_key?(immutable_attr))     # added
        
       action = "Please cancel current deployment and "
       if old_cfg.has_key?(immutable_attr)
         action += "change option #{immutable_attr} back to #{old_cfg[immutable_attr]}"       
       else
         action += "remove option: #{immutable_attr}"
       end  
       msg = "#{immutable_attr} cannot be changed. #{action}"
       Chef::Log.error("#{msg}")
       puts "***FAULT:FATAL="+msg
       e = Exception.new("no backtrace")
       e.set_backtrace("")
       raise e       
    end
  end
end

if node.workorder.rfcCi.has_key?("ciBaseAttributes") && node.workorder.rfcCi.ciBaseAttributes.has_key?("endpoint_snitch")
  old_endpoint_snitch = node.workorder.rfcCi.ciBaseAttributes.endpoint_snitch
  endpoint_snitch = node.workorder.rfcCi.ciAttributes.endpoint_snitch
  if ( node.workorder.rfcCi.ciBaseAttributes.endpoint_snitch != node.workorder.rfcCi.ciAttributes.endpoint_snitch ) && # changed
     !( old_endpoint_snitch =~ /\.PropertyFileSnitch/ && endpoint_snitch =~ /\.GossipingPropertyFileSnitch/) # support change PropertyFileSnitch -> GossipingPropertyFileSnitch
       action = "Please cancel current deployment and change endpoint snitch from #{endpoint_snitch} to #{old_endpoint_snitch} or as supported."       
       msg = "Only PropertyFileSnitch to GossipingPropertyFileSnitch Endoint snitch migration is supported. #{action}"
       Chef::Log.error("#{msg}")
       puts "***FAULT:FATAL="+msg
       e = Exception.new("no backtrace")
       e.set_backtrace("")
       raise e       
    end
end